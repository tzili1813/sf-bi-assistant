import { LightningElement, track, wire } from 'lwc';
import askQuestion from '@salesforce/apex/BIAssistantController.askQuestion';
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
     *               containerClass, bubbleClass, html }
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

    handleClearConversation() {
        this.conversationHistory = [];
        this.displayMessages = [];
        this.question = '';
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
                // Parse response: HTML ===VISUALIZATIONS=== JSON array
                // Falls back to plain HTML if delimiter is not found
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

                const assistantId = this._addDisplayMessage(
                    'assistant', '', htmlContent, visualizations
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

    _addDisplayMessage(type, text, html, visualizations) {
        const id = 'msg-' + (this.msgCounter++);
        const msg = {
            id,
            type,
            text,
            html: html || '',
            visualizations: visualizations && visualizations.length > 0
                ? visualizations : null,
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
