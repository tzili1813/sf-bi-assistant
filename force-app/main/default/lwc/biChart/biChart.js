import { LightningElement, api } from 'lwc';
import ChartJs from '@salesforce/resourceUrl/ChartJs';
import { loadScript } from 'lightning/platformResourceLoader';

export default class BiChart extends LightningElement {
    @api chartConfig; // { type, title, data, options }
    @api height = 300;

    chart;
    chartJsLoaded = false;

    get title() {
        return this.chartConfig?.title || '';
    }

    get containerStyle() {
        return `height: ${this.height}px; position: relative;`;
    }

    renderedCallback() {
        if (this.chartJsLoaded) {
            return;
        }
        this.chartJsLoaded = true;

        loadScript(this, ChartJs)
            .then(() => {
                this.renderChart();
            })
            .catch(error => {
                console.error('Error loading Chart.js:', error);
            });
    }

    @api
    renderChart() {
        if (!this.chartConfig || !window.Chart) return;

        const canvas = this.template.querySelector('canvas');
        if (!canvas) return;

        // Destroy previous chart instance if it exists
        if (this.chart) {
            this.chart.destroy();
        }

        const ctx = canvas.getContext('2d');

        // Clone config to avoid LWC proxy issues
        const config = JSON.parse(JSON.stringify(this.chartConfig));

        const isCircular = config.type === 'doughnut' || config.type === 'pie';

        // Build default options with SLDS styling
        const defaultOptions = {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: {
                    position: isCircular ? 'right' : 'top',
                    labels: {
                        font: {
                            family: 'Salesforce Sans, Arial, sans-serif',
                            size: 12
                        },
                        color: '#444444',
                        padding: 16
                    }
                },
                tooltip: {
                    backgroundColor: '#032d60',
                    titleFont: { family: 'Salesforce Sans, Arial, sans-serif' },
                    bodyFont: { family: 'Salesforce Sans, Arial, sans-serif' },
                    padding: 12,
                    cornerRadius: 4,
                    callbacks: {
                        label: function (context) {
                            let label = context.dataset.label || '';
                            if (label) label += ': ';
                            const value =
                                context.parsed.y !== null &&
                                context.parsed.y !== undefined
                                    ? context.parsed.y
                                    : context.parsed;
                            if (value !== null && value !== undefined) {
                                label += new Intl.NumberFormat().format(value);
                            }
                            return label;
                        }
                    }
                }
            }
        };

        // Add axis formatting for bar/line charts only
        if (config.type === 'bar' || config.type === 'line') {
            defaultOptions.scales = {
                x: {
                    ticks: {
                        font: {
                            family: 'Salesforce Sans, Arial, sans-serif',
                            size: 11
                        },
                        color: '#706e6b'
                    },
                    grid: { color: '#e5e5e5' }
                },
                y: {
                    beginAtZero: true,
                    ticks: {
                        font: {
                            family: 'Salesforce Sans, Arial, sans-serif',
                            size: 11
                        },
                        color: '#706e6b',
                        callback: function (value) {
                            return new Intl.NumberFormat('en-US', {
                                notation: 'compact',
                                maximumFractionDigits: 1
                            }).format(value);
                        }
                    },
                    grid: { color: '#e5e5e5' }
                }
            };
        }

        // Deep-merge user options over defaults (targeted merge to preserve callbacks)
        const userOpts = config.options || {};

        config.options = {
            ...defaultOptions,
            ...userOpts,
            plugins: {
                ...defaultOptions.plugins,
                ...(userOpts.plugins || {}),
                legend: {
                    ...defaultOptions.plugins.legend,
                    ...((userOpts.plugins && userOpts.plugins.legend) || {}),
                    labels: {
                        ...defaultOptions.plugins.legend.labels,
                        ...((userOpts.plugins &&
                            userOpts.plugins.legend &&
                            userOpts.plugins.legend.labels) ||
                            {})
                    }
                },
                tooltip: {
                    ...defaultOptions.plugins.tooltip,
                    ...((userOpts.plugins && userOpts.plugins.tooltip) || {}),
                    // Always keep our formatter callbacks
                    callbacks: defaultOptions.plugins.tooltip.callbacks
                }
            }
        };

        // Merge scales if present (for bar/line charts)
        if (defaultOptions.scales) {
            const userScales = userOpts.scales || {};
            config.options.scales = {
                x: {
                    ...defaultOptions.scales.x,
                    ...(userScales.x || {}),
                    ticks: {
                        ...defaultOptions.scales.x.ticks,
                        ...((userScales.x && userScales.x.ticks) || {})
                    },
                    grid: {
                        ...defaultOptions.scales.x.grid,
                        ...((userScales.x && userScales.x.grid) || {})
                    }
                },
                y: {
                    ...defaultOptions.scales.y,
                    ...(userScales.y || {}),
                    ticks: {
                        ...defaultOptions.scales.y.ticks,
                        ...((userScales.y && userScales.y.ticks) || {})
                    },
                    grid: {
                        ...defaultOptions.scales.y.grid,
                        ...((userScales.y && userScales.y.grid) || {})
                    }
                }
            };
            // Re-apply y-axis callback after merge (user ticks may have overwritten it)
            config.options.scales.y.ticks.callback = function (value) {
                return new Intl.NumberFormat('en-US', {
                    notation: 'compact',
                    maximumFractionDigits: 1
                }).format(value);
            };
        }

        // Add click handler for drilldown
        config.options.onClick = (evt, elements) => {
            if (elements && elements.length > 0) {
                const element = elements[0];
                const datasetIndex = element.datasetIndex;
                const index = element.index;
                const label = config.data.labels ? config.data.labels[index] : '';
                const value = config.data.datasets[datasetIndex]
                    ? config.data.datasets[datasetIndex].data[index]
                    : null;
                const chartTitle = config.title || '';

                this.dispatchEvent(new CustomEvent('drilldown', {
                    detail: { label, value, chartTitle },
                    bubbles: true,
                    composed: true
                }));
            }
        };

        this.chart = new window.Chart(ctx, {
            type: config.type,
            data: config.data,
            options: config.options
        });
    }

    /**
     * Export the chart as a PNG image data URL.
     */
    @api
    exportAsImage() {
        if (this.chart) {
            return this.chart.toBase64Image();
        }
        return null;
    }

    disconnectedCallback() {
        if (this.chart) {
            this.chart.destroy();
        }
    }
}
