<?php
ini_set('display_errors', 1);
error_reporting(E_ALL);

echo "<h1>Inotify Test</h1>";
echo "PHP SAPI: " . php_sapi_name() . "<br>";
echo "PHP Version: " . phpversion() . "<br>";
echo "inotify extension loaded: " . (extension_loaded('inotify') ? '<b>Yes</b>' : '<b>No</b>') . "<br>";

if (!extension_loaded('inotify')) {
    die("<p style='color:red;'>inotify extension not loaded. Cannot proceed.</p>");
}

echo "<hr>";

$fd = null;
$tempFile = null;
$watch_descriptor = null;

try {
    echo "Attempting inotify_init()...<br>";
    $fd = inotify_init();
    if (!$fd) {
        throw new Exception("inotify_init() failed or returned a falsy value.");
    }
    echo "inotify_init() successful. Resource type: " . get_resource_type($fd) . "<br>";

    // Create a dummy file to watch
    $tempFile = tempnam(sys_get_temp_dir(), 'inotify_test_');
    if ($tempFile === false) {
        throw new Exception("tempnam() failed to create a temporary file.");
    }
    touch($tempFile); // Ensure it exists
    echo "Created temporary file to watch: " . htmlspecialchars($tempFile) . "<br>";

    echo "Attempting inotify_add_watch()...<br>";
    $watch_descriptor = inotify_add_watch($fd, $tempFile, IN_MODIFY | IN_CLOSE_WRITE);
    if ($watch_descriptor === false) {
        throw new Exception("inotify_add_watch() failed. PHP error: " . error_get_last()['message']);
    }
    echo "inotify_add_watch() successful. Watch descriptor: " . $watch_descriptor . "<br>";

    echo "Checking if function 'inotify_read_events' exists...<br>";
    if (function_exists('inotify_read_events')) {
        echo "function_exists('inotify_read_events') returns <b>TRUE</b>.<br>";
    } else {
        echo "function_exists('inotify_read_events') returns <b>FALSE</b>.<br>";
        throw new Exception("inotify_read_eventsis not defined according to function_exists(). This is the core problem.");
    }

    echo "Attempting to call inotify_read_events() with IN_NONBLOCK...<br>";
    // Trigger an event
    file_put_contents($tempFile, "some data " . time() . "\n");
    echo "Modified temporary file to trigger event.<br>";

    $events = inotify_read_events($fd, IN_NONBLOCK);

    if ($events === false) {
        echo "inotify_read_events() returned false. For IN_NONBLOCK, this usually means no events were immediately pending (which might be okay if event queue processing is too fast) or an error occurred.<br>";
        // To be more certain, let's try a blocking read for a very short time
        // echo "Attempting a short blocking read...<br>";
        // $events_blocking = inotify_read_events($fd); // This will block
        // if ($events_blocking === false) echo "Blocking read also returned false (error).<br>";
        // else echo "Blocking read events: <pre>" . htmlspecialchars(print_r($events_blocking, true)) . "</pre><br>";

    } elseif (is_array($events)) {
        echo "inotify_read_events() successful. Events received: <pre>" . htmlspecialchars(print_r($events, true)) . "</pre><br>";
    } else {
        echo "inotify_read_events() returned an unexpected value: " . htmlspecialchars(var_export($events, true)) . "<br>";
    }

    echo "<p style='color:green;'>Test appears to have passed the inotify_read_events() call point.</p>";

} catch (Throwable $e) { // Catch any error or exception
    echo "<p style='color:red;'><b>TEST FAILED:</b> " . htmlspecialchars($e->getMessage()) . "</p>";
    echo "<p>File: " . htmlspecialchars($e->getFile()) . " on line " . htmlspecialchars($e->getLine()) . "</p>";
    echo "<pre>" . htmlspecialchars($e->getTraceAsString()) . "</pre>";
} finally {
    if ($watch_descriptor !== null && $fd !== null && is_resource($fd)) {
        @inotify_rm_watch($fd, $watch_descriptor);
        echo "Removed watch descriptor.<br>";
    }
    if ($fd !== null && is_resource($fd)) {
        @fclose($fd);
        echo "Closed inotify file descriptor.<br>";
    }
    if ($tempFile !== null && file_exists($tempFile)) {
        @unlink($tempFile);
        echo "Deleted temporary file: " . htmlspecialchars($tempFile) . "<br>";
    }
}

echo "<hr>Test completed.<br>";
?>
