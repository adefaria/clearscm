<?php
header('Content-Type: application/json');

// Ensure this path is identical to the one in logviewer.php
$logFile = '/web/pm/playback.log';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(['success' => false, 'error' => 'Invalid request method. Only POST is allowed.']);
    exit;
}

if (file_exists($logFile)) {
    if (is_writable($logFile)) {
        // Truncate the file by opening it in write mode and immediately closing, or using file_put_contents
        if (file_put_contents($logFile, '') !== false) {
            echo json_encode(['success' => true, 'message' => 'Log file cleared successfully.']);
        } else {
            echo json_encode(['success' => false, 'error' => 'Failed to write to (clear) log file. Check permissions.']);
        }
    } else {
        echo json_encode(['success' => false, 'error' => 'Log file is not writable. Check permissions.']);
    }
} else {
    // If the file doesn't exist, arguably it's already "clear".
    echo json_encode(['success' => true, 'message' => 'Log file does not exist, so it is effectively clear.']);
}
?>