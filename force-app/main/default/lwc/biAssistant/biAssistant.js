import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LightningConfirm from 'lightning/confirm';
import askQuestion from '@salesforce/apex/BIAssistantController.askQuestion';
import confirmAction from '@salesforce/apex/BIAssistantController.confirmAction';
import getAvailableModels from '@salesforce/apex/BIAssistantController.getAvailableModels';

/**
 * biAssistant
 * -----------
 * Chat-style BI assistant that keeps a multi-turn conversation context.
 *
 * Conversation flow:
 *   1. User types a question.
 *   2. LWC sends the question + full conversation history to Apex.
 *   3. Apex runs Pass 1 (NL→SOQL) and Pass 2 (results→HTML) against
 *      the Models API, returning the HTML analysis and an updated history.
 *   4. LWC renders the HTML and stores the updated history for the next turn.
 *
 * The `conversationHistory` array (List<BIChatMessage>) is what gets sent
 * to the Models API as the message list — enabling multi-turn context.
 */
const STORAGE_KEY = 'bi-assistant-state';

export default class BiAssistant extends LightningElement {

    question = '';
    selectedModel = '';
    @track modelOptions = [];

    /**
     * Internal conversation history sent to Apex (mirrors the Models API
     * message format: {role, content}).  The LWC never displays this
     * directly — it is purely the LLM's context window.
     */
    @track conversationHistory = [];

    /** Load available models via cacheable wire */
    @wire(getAvailableModels)
    wiredModels({ data, error }) {
        if (data) {
            this.modelOptions = data.map(m => ({
                label: m.label,
                value: m.value
            }));
            if (this.modelOptions.length > 0 && !this.selectedModel) {
                this.selectedModel = this.modelOptions[0].value;
            }
        } else if (error) {
            console.error('Failed to load models:', error);
        }
    }

    /**
     * Display messages shown in the UI thread.
     * Each entry: { id, type, text, isUser, isAssistant, isLoading, isError,
     *               containerClass, bubbleClass, html, visualizations,
     *               queries, showSoql, suggestedFollowUps }
     */
    @track displayMessages = [];

    @track isLoading = false;
    loadingMessage = 'Analyzing your data...';

    msgCounter = 0;

    exampleQuestions = [
        'How many open opportunities do we have by stage?',
        'Show me closed-won deals from last quarter',
        'How many open cases by priority and status?',
        'Which accounts have the most escalated cases?',
        'What is our average case resolution time this month?',
        'Show me SLA compliance by entitlement'
    ];

    // ── Lifecycle ──────────────────────────────────────────────

    connectedCallback() {
        this._restoreState();
    }

    // ── Computed ─────────────────────────────────────────────────

    get isAskDisabled() {
        return !this.question || this.isLoading;
    }

    get hasMessages() {
        return this.displayMessages.length > 0;
    }

    get hasModels() {
        return this.modelOptions.length > 0;
    }

    // ── Event handlers ──────────────────────────────────────────

    handleModelChange(event) {
        this.selectedModel = event.detail.value;
    }

    handleQuestionChange(event) {
        this.question = event.target.value;
    }

    handleKeyUp(event) {
        if (event.keyCode === 13) {
            this.handleAsk();
        }
    }

    handleExampleClick(event) {
        this.question = event.target.textContent;
        this.handleAsk();
    }

    handleSuggestionClick(event) {
        this.question = event.target.dataset.question;
        this.handleAsk();
    }

    handleClearConversation() {
        this.conversationHistory = [];
        this.displayMessages = [];
        this.question = '';
        this._clearStoredState();
    }

    handleToggleSoql(event) {
        const msgId = event.target.dataset.msgId;
        this.displayMessages = this.displayMessages.map(m => {
            if (m.id === msgId) {
                return { ...m, showSoql: !m.showSoql };
            }
            return m;
        });
    }

    async handleActionConfirm(event) {
        const actionId = event.target.dataset.actionId;
        const msgId = event.target.dataset.msgId;

        // Find the action proposal
        const msg = this.displayMessages.find(m => m.id === msgId);
        if (!msg || !msg.suggestedActions) return;
        const action = msg.suggestedActions.find(a => a.proposalId === actionId);
        if (!action) return;

        // Confirmation dialog
        const confirmed = await LightningConfirm.open({
            message: action.label + '\n\nReason: ' + (action.reasoning || 'Recommended based on the analysis.'),
            label: 'Confirm Action',
            theme: 'warning'
        });

        if (!confirmed) return;

        // Mark action as executing
        this._updateAction(msgId, actionId, { executing: true });

        try {
            const result = await confirmAction({
                actionJson: JSON.stringify(action)
            });

            if (result.success) {
                this._updateAction(msgId, actionId, {
                    executing: false,
                    completed: true,
                    recordUrl: result.recordUrl,
                    recordId: result.recordId
                });
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Action Completed',
                    message: action.label,
                    variant: 'success'
                }));
            } else {
                this._updateAction(msgId, actionId, {
                    executing: false,
                    failed: true,
                    errorMessage: result.errorMessage
                });
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Action Failed',
                    message: result.errorMessage,
                    variant: 'error'
                }));
            }
        } catch (error) {
            const errMsg = error.body ? error.body.message : error.message;
            this._updateAction(msgId, actionId, {
                executing: false,
                failed: true,
                errorMessage: errMsg
            });
        }

        this._saveState();
    }

    handleActionDismiss(event) {
        const actionId = event.target.dataset.actionId;
        const msgId = event.target.dataset.msgId;
        this._updateAction(msgId, actionId, { dismissed: true });
        this._saveState();
    }

    _updateAction(msgId, actionId, updates) {
        this.displayMessages = this.displayMessages.map(m => {
            if (m.id === msgId && m.suggestedActions) {
                return {
                    ...m,
                    suggestedActions: m.suggestedActions.map(a => {
                        if (a.proposalId === actionId) {
                            return { ...a, ...updates };
                        }
                        return a;
                    })
                };
            }
            return m;
        });
    }

    handleDrilldown(event) {
        const { label, chartTitle } = event.detail;
        if (label) {
            this.question = `Tell me more about "${label}" from the ${chartTitle || 'chart'}`;
            this.handleAsk();
        }
    }

    handleExportCsv(event) {
        const msgId = event.target.dataset.msgId;
        const msg = this.displayMessages.find(m => m.id === msgId);
        if (!msg || !msg.queryRows) return;

        // Build CSV from stored query rows
        const rows = msg.queryRows;
        if (!rows || rows.length === 0) return;

        const headers = Object.keys(rows[0]);
        const csvLines = [headers.join(',')];
        for (const row of rows) {
            const values = headers.map(h => {
                let val = row[h];
                if (val === null || val === undefined) val = '';
                val = String(val).replace(/"/g, '""');
                return `"${val}"`;
            });
            csvLines.push(values.join(','));
        }

        const csvContent = csvLines.join('\n');
        const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
        const url = URL.createObjectURL(blob);
        const link = document.createElement('a');
        link.href = url;
        link.download = 'bi-assistant-export.csv';
        link.click();
        URL.revokeObjectURL(url);
    }

    // ── Main ask flow ───────────────────────────────────────────

    async handleAsk() {
        if (!this.question || this.isLoading) return;

        const userQuestion = this.question;
        this.question = '';
        this.isLoading = true;

        // 1. Add user message bubble
        this._addDisplayMessage('user', userQuestion);

        // 2. Add loading bubble
        const loadingId = this._addDisplayMessage('loading', '');

        // 3. Rotate loading messages
        this._startLoadingAnimation();

        try {
            // 4. Call Apex with full conversation history
            const result = await askQuestion({
                question: userQuestion,
                conversationHistoryJson: JSON.stringify(this.conversationHistory),
                modelName: this.selectedModel || null
            });

            // 5. Remove loading bubble
            this._removeDisplayMessage(loadingId);

            if (result.errorMessage) {
                // Show error in thread
                this._addDisplayMessage('error', result.errorMessage);
            } else {
                // Parse response: HTML ===VISUALIZATIONS=== JSON ===SUGGESTIONS=== JSON
                const response = result.analysisHtml || '';
                let htmlContent = response;
                let visualizations = [];

                const delimiter = '===VISUALIZATIONS===';
                const delimIdx = response.indexOf(delimiter);

                if (delimIdx !== -1) {
                    htmlContent = response.substring(0, delimIdx).trim();
                    const vizJson = response.substring(
                        delimIdx + delimiter.length
                    ).trim();
                    try {
                        const vizArray = JSON.parse(vizJson);
                        if (Array.isArray(vizArray)) {
                            visualizations = vizArray.map((viz, idx) => ({
                                ...viz,
                                id: 'viz-' + this.msgCounter + '-' + idx
                            }));
                        }
                    } catch (e) {
                        // Malformed viz JSON — show HTML only
                    }
                }

                // Build SOQL display text and gather rows for CSV export
                let soqlText = '';
                let allRows = [];
                if (result.queries && result.queries.length > 0) {
                    soqlText = result.queries
                        .map(q => `-- ${q.label} (${q.recordCount} records)\n${q.soql}`)
                        .join('\n\n');
                    // Flatten rows from all queries for CSV
                    for (const q of result.queries) {
                        if (q.rows) {
                            allRows = allRows.concat(q.rows);
                        }
                    }
                }

                // Gather follow-up suggestions and actions
                const suggestions = result.suggestedFollowUps || [];
                const actions = (result.suggestedActions || []).map((a, i) => ({
                    ...a,
                    proposalId: a.proposalId || `action-${i}`,
                    executing: false,
                    completed: false,
                    failed: false,
                    dismissed: false,
                    errorMessage: null,
                    recordUrl: null,
                    recordId: null
                }));

                const assistantId = this._addDisplayMessage(
                    'assistant', '', htmlContent, visualizations,
                    soqlText, suggestions, actions, allRows
                );

                // Update conversation history for next turn
                if (result.updatedHistory) {
                    this.conversationHistory = result.updatedHistory;
                }

                // Render the HTML into the DOM after the template updates
                // eslint-disable-next-line @lwc/lwc/no-async-operation
                setTimeout(() => {
                    this._renderHtml(assistantId, htmlContent);
                }, 0);
            }

            // Persist conversation state
            this._saveState();
        } catch (error) {
            this._removeDisplayMessage(loadingId);
            const msg = error.body ? error.body.message : error.message || 'An unexpected error occurred.';
            this._addDisplayMessage('error', msg);
        } finally {
            this.isLoading = false;
            this._stopLoadingAnimation();
            this._scrollToBottom();
        }
    }

    // ── Display message management ──────────────────────────────

    _addDisplayMessage(type, text, html, visualizations, soqlText, suggestions, actions, queryRows) {
        const id = 'msg-' + (this.msgCounter++);
        const msg = {
            id,
            type,
            text,
            html: html || '',
            visualizations: visualizations && visualizations.length > 0
                ? visualizations : null,
            soqlText: soqlText || '',
            showSoql: false,
            hasSoql: Boolean(soqlText),
            queryRows: queryRows && queryRows.length > 0 ? queryRows : null,
            hasExportData: queryRows && queryRows.length > 0,
            suggestedFollowUps: suggestions && suggestions.length > 0
                ? suggestions.map((s, i) => ({ id: `sug-${id}-${i}`, text: s }))
                : null,
            suggestedActions: actions && actions.length > 0 ? actions : null,
            hasActions: actions && actions.length > 0,
            timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
            isUser:      type === 'user',
            isAssistant: type === 'assistant',
            isLoading:   type === 'loading',
            isError:     type === 'error',
            showTimestamp: type !== 'loading',
            containerClass: 'message-container '
                + (type === 'user' ? 'user-container' : 'assistant-container'),
            bubbleClass: 'message-bubble '
                + (type === 'user'      ? 'user-bubble'      : '')
                + (type === 'assistant' ? 'assistant-bubble'  : '')
                + (type === 'loading'   ? 'loading-bubble'    : '')
                + (type === 'error'     ? 'error-bubble'      : '')
        };
        this.displayMessages = [...this.displayMessages, msg];
        return id;
    }

    _removeDisplayMessage(id) {
        this.displayMessages = this.displayMessages.filter(m => m.id !== id);
    }

    /**
     * Strip dangerous patterns from LLM-generated HTML before injection.
     */
    _sanitizeHtml(html) {
        if (!html) return '';
        html = html.replace(/<script[\s\S]*?<\/script>/gi, '');
        html = html.replace(/\bon\w+\s*=\s*["'][^"']*["']/gi, '');
        html = html.replace(/\bon\w+\s*=\s*[^\s>]*/gi, '');
        html = html.replace(/javascript\s*:/gi, '');
        return html;
    }

    /**
     * Inject sanitized HTML into the lwc:dom="manual" container for a given message.
     */
    _renderHtml(msgId, html) {
        const containers = this.template.querySelectorAll('.analysis-content');
        for (const el of containers) {
            if (el.dataset.msgId === msgId) {
                el.innerHTML = this._sanitizeHtml(html);
                break;
            }
        }
    }

    /**
     * Re-render all assistant HTML after restoring from localStorage.
     */
    _rerenderAllHtml() {
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        setTimeout(() => {
            for (const msg of this.displayMessages) {
                if (msg.isAssistant && msg.html) {
                    this._renderHtml(msg.id, msg.html);
                }
            }
        }, 0);
    }

    // ── Conversation persistence (localStorage) ──────────────────

    _saveState() {
        try {
            const state = {
                displayMessages: this.displayMessages,
                conversationHistory: this.conversationHistory,
                msgCounter: this.msgCounter,
                selectedModel: this.selectedModel
            };
            localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
        } catch (e) {
            // localStorage full or unavailable — fail silently
        }
    }

    _restoreState() {
        try {
            const raw = localStorage.getItem(STORAGE_KEY);
            if (!raw) return;
            const state = JSON.parse(raw);
            if (state.displayMessages && state.displayMessages.length > 0) {
                this.displayMessages = state.displayMessages;
                this.conversationHistory = state.conversationHistory || [];
                this.msgCounter = state.msgCounter || this.displayMessages.length;
                if (state.selectedModel) {
                    this.selectedModel = state.selectedModel;
                }
                // Re-inject HTML into lwc:dom="manual" containers
                this._rerenderAllHtml();
            }
        } catch (e) {
            // Corrupt state — start fresh
            this._clearStoredState();
        }
    }

    _clearStoredState() {
        try {
            localStorage.removeItem(STORAGE_KEY);
        } catch (e) {
            // Ignore
        }
    }

    // ── Loading animation ───────────────────────────────────────

    _loadingInterval = null;
    _loadingPhases = [
        'Translating your question...',
        'Querying your data...',
        'Running analysis...',
        'Formatting results...'
    ];
    _loadingPhaseIndex = 0;

    _startLoadingAnimation() {
        this._loadingPhaseIndex = 0;
        this.loadingMessage = this._loadingPhases[0];
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this._loadingInterval = setInterval(() => {
            this._loadingPhaseIndex =
                (this._loadingPhaseIndex + 1) % this._loadingPhases.length;
            this.loadingMessage = this._loadingPhases[this._loadingPhaseIndex];
        }, 2500);
    }

    _stopLoadingAnimation() {
        if (this._loadingInterval) {
            clearInterval(this._loadingInterval);
            this._loadingInterval = null;
        }
    }

    _scrollToBottom() {
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        setTimeout(() => {
            const thread = this.template.querySelector('.conversation-thread');
            if (thread) {
                thread.scrollTop = thread.scrollHeight;
            }
        }, 100);
    }
}
