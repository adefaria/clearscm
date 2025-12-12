<?php
ini_set('display_errors', 0); // ALWAYS OFF for SSE
ini_set('log_errors', 1); // Log errors to a file
ini_set('error_log', '/var/log/php_logstream_errors.log'); // Choose a writable path
error_reporting(E_ALL);

header('Content-Type: text/event-stream');
header('Cache-Control: no-cache');
header('Connection: keep-alive');
header('X-Accel-Buffering: no'); // For Nginx proxy

// Ensure output is sent immediately without buffering
if (ob_get_level() > 0) {
    for ($i = 0; $i < ob_get_level(); $i++) {
        ob_end_flush();
    }
}
ob_implicit_flush(1);

@apache_setenv('no-gzip', 1);
ini_set('zlib.output_compression', 0);

set_time_limit(0); // Allow script to run indefinitely

$logFile = '/web/pm/playback.log'; // Ensure this path is correct
$currentLineCount = 0;

function send_sse_message($data, $event_name = 'logupdate')
{
    echo "event: " . $event_name . "\n";
    echo "data: " . json_encode($data) . "\n\n";
    // ob_flush(); // Not needed with ob_implicit_flush(1)
    flush();
}

function send_initial_log_state($filePath, &$lineCount)
{
    if (file_exists($filePath) && is_readable($filePath)) {
        $content = file($filePath, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
        if ($content !== false) {
            send_sse_message(['type' => 'full_log', 'lines' => $content]);
            $lineCount = count($content);
            return;
        }
    }
    send_sse_message(['type' => 'full_log', 'lines' => [], 'message' => 'Log file not found or not readable at startup.']);
    $lineCount = 0;
}

function check_and_send_log_changes($filePath, &$lineCount)
{
    clearstatcache(true, $filePath); // Essential for getting fresh file info

    if (!file_exists($filePath) || !is_readable($filePath)) {
        if ($lineCount > 0 || file_exists($filePath)) { // Only send if there was a change (e.g. file deleted)
            send_sse_message(['type' => 'log_cleared_or_missing', 'message' => "Log file '$filePath' disappeared or became unreadable."]);
        }
        $lineCount = 0;
        return false; // Indicate failure to process, maybe stop watching
    }

    $all_lines = file($filePath, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    if ($all_lines === false) {
        send_sse_message(['type' => 'error', 'message' => "Failed to read log file: $filePath"]);
        return true; // Continue watching, might be a temporary issue
    }

    $new_total_lines = count($all_lines);

    if ($new_total_lines < $lineCount) { // Log was truncated
        send_sse_message(['type' => 'truncated', 'lines' => $all_lines]);
    } elseif ($new_total_lines > $lineCount) { // New lines available
        $new_lines = array_slice($all_lines, $lineCount);
        send_sse_message(['type' => 'new_lines', 'lines' => $new_lines]);
    }
    // If $new_total_lines == $lineCount, no change in line count.
    // Could add more sophisticated checks for content change if needed.

    $lineCount = $new_total_lines;
    return true;
}

if (!extension_loaded('inotify')) {
    send_sse_message(['type' => 'error', 'message' => 'inotify extension not loaded on server. Real-time updates unavailable.']);
    exit;
}

$inotify = inotify_init();
if (!$inotify) {
    send_sse_message(['type' => 'error', 'message' => 'Failed to initialize inotify.']);
    exit;
}

// Attempt to add watch. If log file doesn't exist, inotify_add_watch will fail.
// We'll try to create it if it's missing, then watch.
if (!file_exists($logFile)) {
    if (@touch($logFile) === false) {
        send_sse_message(['type' => 'error', 'message' => "Log file '$logFile' does not exist and could not be created."]);
        fclose($inotify);
        exit;
    }
    chmod($logFile, 0664); // Ensure web server can write if it creates it, and read
}
clearstatcache(true, $logFile);

$watch_descriptor = @inotify_add_watch($inotify, $logFile, IN_MODIFY | IN_CLOSE_WRITE | IN_ATTRIB | IN_DELETE_SELF | IN_MOVE_SELF | IN_CREATE);

if ($watch_descriptor === false) {
    send_sse_message(['type' => 'error', 'message' => "Failed to watch log file '$logFile'. Check permissions or if path is correct."]);
    fclose($inotify);
    exit;
}

// Send the initial state of the log file
send_initial_log_state($logFile, $currentLineCount);

$last_ping_time = time();

while (true) {
    if (connection_aborted()) {
        break; // Client disconnected
    }

    // Send a keep-alive comment every 20 seconds if no other data
    if (time() - $last_ping_time > 20) {
        echo ": keepalive\n\n"; // SSE comment
        // ob_flush(); // Not needed
        flush();
        $last_ping_time = time();
    }

    // Check for inotify events (non-blocking).
    // Ensure the resource is still valid before reading.
    $events = (is_resource($inotify) && function_exists('inotify_read_events'))
        ? inotify_read_events($inotify, IN_NONBLOCK)
        : false;

    if ($events) {
        $last_ping_time = time(); // Reset ping timer on activity
        $fileChanged = false;
        foreach ($events as $event) {
            if ($event['mask'] & (IN_MODIFY | IN_CLOSE_WRITE | IN_ATTRIB)) {
                $fileChanged = true;
            }
            if ($event['mask'] & (IN_DELETE_SELF | IN_MOVE_SELF)) {
                send_sse_message(['type' => 'log_moved_or_deleted', 'message' => 'Log file was moved or deleted. Stream will close. Please refresh.']);
                inotify_rm_watch($inotify, $watch_descriptor);
                fclose($inotify);
                exit; // End script as the watched file is gone. Client should reconnect.
            }
            // If IN_CREATE is watched on the *directory*, this could handle recreation.
            // For simplicity, if the file is deleted, we exit. Client can retry.
        }
        if ($fileChanged) {
            if (!check_and_send_log_changes($logFile, $currentLineCount)) {
                // If check_and_send_log_changes returns false (e.g. file gone), exit.
                inotify_rm_watch($inotify, $watch_descriptor);
                fclose($inotify);
                exit;
            }
        }
    } else {
        // No events, sleep briefly to avoid busy-waiting
        usleep(250000); // 250ms
    }
}

if ($watch_descriptor !== false && $inotify) {
    @inotify_rm_watch($inotify, $watch_descriptor);
}
if ($inotify) {
    @fclose($inotify);
}
?>