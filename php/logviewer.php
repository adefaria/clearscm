<!DOCTYPE html>
<html>

<head>
    <title>Playback Log Viewer</title>
    <meta charset="utf-8">
    <style>
        body {
            font-family: monospace;
            white-space: pre-wrap;
            background-color: #222;
            color: #eee;
            padding: 20px;
        }

        #log-container {
            border: 1px solid #555;
            padding: 10px;
            overflow-y: auto;
            box-sizing: border-box;
            /* Ensures padding is included in the height */
            max-height: 80vh;
            line-height: 1.2;
            /* Explicit line-height for better calculation consistency */
            background-color: #000;
            color: #0f0;
        }

        /* Common styles for action buttons */
        .action-button {
            padding: 10px 20px;
            color: white;
            border: none;
            cursor: pointer;
        }

        #refresh-button {
            background-color: #4CAF50;
            /* Green */
        }

        #clear-log-button {
            background-color: #f44336;
            /* Red */
            margin-left: 10px;
        }
    </style>
</head>

<body>
    <h1>Playback Log</h1>
    <div style="display: flex; align-items: center; margin-bottom: 10px;">
        <button id="refresh-button" class="action-button">Refresh Log</button>
        <button id="clear-log-button" class="action-button">Empty Log</button>
    </div>
    <div id="log-container"></div> <!-- Initially empty, content loaded by JS -->

    <script>
        const logContainer = document.getElementById('log-container');
        const refreshButton = document.getElementById('refresh-button');
        const clearLogButton = document.getElementById('clear-log-button');
        const linesInViewport = 25; // Desired number of text lines in the viewport
        let displayedLineCount = 0; // Still useful for knowing current client state if needed
        let eventSource = null;

        function calculateAndSetContainerHeight(container, numTextLines) {
            if (!container || numTextLines <= 0) return;

            let singleLineHeight = 0;
            const computedContainerStyle = window.getComputedStyle(container);

            // Get the computed font-size of the container itself.
            // This should resolve to a pixel value (e.g., "16px").
            const containerFontSizePxString = computedContainerStyle.fontSize;
            const containerFontSizePx = parseFloat(containerFontSizePxString);

            console.log(`Container computed font-size string: ${containerFontSizePxString}`);

            if (isNaN(containerFontSizePx) || containerFontSizePx <= 0) {
                console.error("Could not determine container font size in pixels. Aborting height calculation.");
                // As a last resort, try to set a reasonable fixed height if font size fails
                // This is a fallback to prevent the container from having zero or undefined height.
                // 16px (typical default font) * 1.2 line-height * 25 lines + 20px padding
                container.style.height = `${(16 * 1.2 * 25) + 20}px`;
                console.log(`Fell back to a default calculated height: ${container.style.height}`);
                return;
            }

            // The line-height is set to 1.2 (unitless) in CSS for #log-container.
            // This means 1.2 * font-size.
            singleLineHeight = Math.round(containerFontSizePx * 1.2);
            console.log(`Calculated singleLineHeight based on container font-size (${containerFontSizePx}px) and line-height 1.2: ${singleLineHeight}px`);

            // Ensure singleLineHeight is a positive integer, as offsetHeight would be.
            singleLineHeight = Math.max(1, Math.round(singleLineHeight));
            if (singleLineHeight <= 0) {
                console.error("Calculated singleLineHeight is not positive. Aborting.");
                // Fallback height if singleLineHeight is invalid
                container.style.height = `${(16 * 1.2 * 25) + 20}px`;
                console.log(`Fell back to a default calculated height due to invalid singleLineHeight: ${container.style.height}`);
                return;
            }

            // This is the height needed for the text content itself
            const contentHeightForText = singleLineHeight * numTextLines;
            console.log(`Calculated contentHeightForText for ${numTextLines} lines: ${contentHeightForText}px`);

            let targetHeight;
            // If box-sizing is border-box, the style.height includes padding.
            // So, we need to add padding to the contentHeightForText.
            if (computedContainerStyle.boxSizing === 'border-box') {
                const paddingTop = parseFloat(computedContainerStyle.paddingTop) || 0;
                const paddingBottom = parseFloat(computedContainerStyle.paddingBottom) || 0;
                targetHeight = contentHeightForText + paddingTop + paddingBottom;
                console.log(`Box-sizing: border-box. PaddingTop: ${paddingTop}px, PaddingBottom: ${paddingBottom}px. TargetHeight: ${targetHeight}px`);
            } else { // content-box (default)
                targetHeight = contentHeightForText;
                console.log(`Box-sizing: content-box. TargetHeight: ${targetHeight}px`);
            }

            container.style.height = targetHeight + 'px';
            // Note: The CSS 'max-height: 80vh' will still cap this if targetHeight is larger.
            console.log(`Set container style.height to: ${targetHeight}px`);

            // For debugging, let's see what the browser says its height is AFTER we set it.
            // And also check scrollHeight vs clientHeight
            requestAnimationFrame(() => {
                const newComputedStyle = window.getComputedStyle(container);
                console.log(`After setting style.height, container computed CSS height: ${newComputedStyle.height}, clientHeight: ${container.clientHeight}px, scrollHeight: ${container.scrollHeight}px`);
                if (container.scrollHeight > container.clientHeight) {
                    console.log("Content is overflowing the container (scrollbar expected).");
                } else {
                    console.log("Content fits within the container (no scrollbar expected).");
                }
            });
        }

        function scrollToBottom(container) {
            if (container) {
                container.scrollTop = container.scrollHeight;
            }
        }

        function connectEventSource() {
            if (eventSource) {
                eventSource.close();
            }

            eventSource = new EventSource('/php/logstream.php');
            // Clear previous content and show connecting message
            logContainer.innerHTML = '<div>Connecting to log stream...</div>';
            displayedLineCount = 0;

            eventSource.onopen = function () {
                console.log("SSE Connection opened.");
                // Server will send initial log state via 'logupdate' event with type 'full_log'
            };

            eventSource.addEventListener('logupdate', function (event) {
                const data = JSON.parse(event.data);
                handleLogData(data);
            });

            eventSource.onerror = function (err) {
                console.error("EventSource failed:", err);
                console.log(`EventSource readyState: ${eventSource.readyState} (0=CONNECTING, 1=OPEN, 2=CLOSED)`);
                let message = '<div>Connection to log stream lost.';
                if (eventSource.readyState === EventSource.CONNECTING) {
                    message += ' Attempting to reconnect...</div>';
                }
                // Avoid appending multiple error messages if already showing one
                if (!logContainer.innerHTML.includes("Connection to log stream lost")) {
                    logContainer.innerHTML += message;
                }
            };
        }

        function handleLogData(data) {
            if (!data || !data.type) {
                console.warn("Received malformed data from SSE:", data);
                return;
            }

            // Clear "Connecting..." or "Log is empty" message if it's the only thing there
            if (logContainer.children.length === 1 &&
                (logContainer.firstChild.textContent.startsWith('Connecting') || logContainer.firstChild.textContent.startsWith('Log is currently empty'))) {
                logContainer.innerHTML = '';
            }

            switch (data.type) {
                case 'full_log':
                case 'truncated':
                    logContainer.innerHTML = ''; // Clear existing content
                    if (data.lines && data.lines.length > 0) {
                        data.lines.forEach(line => {
                            const lineElement = document.createElement('div');
                            lineElement.textContent = line;
                            logContainer.appendChild(lineElement);
                        });
                        displayedLineCount = data.lines.length;
                    } else {
                        logContainer.innerHTML = `<div>${data.message || 'Log is currently empty.'}</div>`;
                        displayedLineCount = 0;
                    }
                    scrollToBottom(logContainer);
                    return;
                case 'new_lines':
                    if (data.lines && data.lines.length > 0) {
                        data.lines.forEach(line => {
                            const lineElement = document.createElement('div');
                            lineElement.textContent = line;
                            logContainer.appendChild(lineElement);
                        });
                        displayedLineCount += data.lines.length;
                        scrollToBottom(logContainer);
                    }
                    return;
                case 'log_cleared_or_missing':
                    logContainer.innerHTML = `<div>${data.message || 'Log file cleared or is missing.'}</div>`;
                    displayedLineCount = 0;
                    return;
                case 'log_moved_or_deleted':
                case 'error': // Server-side errors from logstream.php
                    logContainer.innerHTML += `<div style="color: red;">${data.message}</div>`;
                    if (eventSource && data.type === 'error') eventSource.close(); // Stop retrying on fatal server error
                    return;
                default:
                    console.warn("Unknown SSE event type:", data.type, data);
            }
        }

        // Event Listeners and Initial Load
        document.addEventListener('DOMContentLoaded', () => {
            calculateAndSetContainerHeight(logContainer, linesInViewport);
            connectEventSource();
        });

        refreshButton.addEventListener('click', () => {
            // Reconnect to the SSE stream to get a fresh state
            connectEventSource();
        });

        clearLogButton.addEventListener('click', async () => {
            if (!confirm('Are you sure you want to clear the log file? This action cannot be undone.')) {
                return;
            }
            // No need to stop EventSource, server should detect change and send update
            try {
                const response = await fetch('/php/clearLog.php', { method: 'POST' });
                const result = await response.json();

                if (result.success) {
                    // The SSE 'log_cleared_or_missing' event will handle updating the UI,
                    // but we can clear it immediately for a faster user experience.
                    logContainer.innerHTML = '<div>Log file cleared.</div>';
                    displayedLineCount = 0;
                } else {
                    alert('Error: ' + (result.error || 'Unknown error occurred while clearing log.'));
                }
            } catch (error) {
                console.error('Error calling clearLog.php:', error);
                alert('Failed to communicate with the server to clear the log file. See console for details.');
            }
        });
    </script>
</body>

</html>