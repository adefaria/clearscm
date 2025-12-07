<?php
header('Content-Type: application/json');

// This path MUST match the log file path used in logviewer.php and clearLog.php
$logFile = '/web/pm/playback.log';

$response = [];

// Get the number of lines the client already knows about
$known_lines_count = isset($_GET['known_lines']) ? (int) $_GET['known_lines'] : 0;

if (!file_exists($logFile)) {
    $response['status'] = 'no_file';
    $response['message'] = "Log file '$logFile' does not exist.";
    $response['new_total_lines'] = 0;
    $response['lines'] = [];
} elseif (!is_readable($logFile)) {
    $response['status'] = 'not_readable';
    $response['error'] = "Log file '$logFile' is not readable.";
    $response['new_total_lines'] = $known_lines_count; // Assume no change if unreadable
    $response['lines'] = [];
} else {
    $all_lines = file($logFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    if ($all_lines === false) {
        $response['status'] = 'read_error';
        $response['error'] = "Failed to read log file: $logFile";
        $response['new_total_lines'] = $known_lines_count;
        $response['lines'] = [];
    } else {
        $current_total_lines = count($all_lines);
        $response['new_total_lines'] = $current_total_lines;

        if ($known_lines_count === 0 && $current_total_lines > 0) { // Initial full load or refresh
            $response['status'] = 'full_data';
            $response['lines'] = $all_lines;
        } elseif ($current_total_lines > $known_lines_count) { // New lines available
            $response['status'] = 'new_data';
            $response['lines'] = array_slice($all_lines, $known_lines_count);
        } elseif ($current_total_lines < $known_lines_count) { // Log was truncated
            $response['status'] = 'truncated';
            $response['lines'] = $all_lines; // Send the new full content
        } else { // No change in line count
            $response['status'] = 'no_change';
            $response['lines'] = [];
        }
    }
}

echo json_encode($response);
?>