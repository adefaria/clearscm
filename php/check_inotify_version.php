<?php
ini_set('display_errors', 1);
error_reporting(E_ALL);

echo "<h1>Inotify Extension Version Check</h1>";

if (extension_loaded('inotify')) {
    $version = phpversion('inotify');
    if ($version) {
        echo "<p><b>inotify extension is loaded.</b></p>";
        echo "<p>Version: <b style='font-size: 1.2em;'>" . htmlspecialchars($version) . "</b></p>";

        if (version_compare($version, '3.0.0', '<')) {
            echo "<p style='color:red; font-weight:bold;'>This version (" . htmlspecialchars($version) . ") is older than the recommended 3.0.0. For PHP 8.3, you should be using version 3.0.0 (beta) or newer from PECL.</p>";
            echo "<p>Older versions (like 0.1.6 from 2012) are highly likely to be incompatible with PHP 8.3. This incompatibility can manifest as missing functions (like <code>inotify_read_events()</code>) or undefined constants (like <code>IN_NONBLOCK</code>), even if other parts of the extension seem to load.</p>";
            echo "<p><b>Action:</b> You should uninstall this version and install <code>inotify-3.0.0</code> using PECL: <code>sudo pecl install inotify-3.0.0</code></p>";
        } elseif (version_compare($version, '3.0.0', '==')) {
            echo "<p style='color:green; font-weight:bold;'>You have version 3.0.0. This is the recommended version for PHP 8.x compatibility.</p>";
            echo "<p>If you are still experiencing issues like 'undefined function inotify_read_events()' or 'undefined constant IN_NONBLOCK' with this version, it strongly indicates that the build of <code>inotify-3.0.0</code> on your system was incomplete or corrupted. This often points to underlying issues with your PECL build environment (e.g., missing <code>php8.3-dev</code>, <code>php8.3-xml</code>, or other essential build tools).</p>";
            echo "<p><b>Action:</b> Ensure your build environment is healthy (install <code>php8.3-dev</code>, <code>php8.3-xml</code>, <code>build-essential</code>), then perform a clean reinstall of <code>inotify-3.0.0</code> (uninstall, clear cache, install).</p>";
        } else {
            // For versions newer than 3.0.0, if any appear in the future
            echo "<p style='color:green; font-weight:bold;'>You have version " . htmlspecialchars($version) . ", which is newer than or equal to 3.0.0. This should generally be compatible.</p>";
            echo "<p>If issues persist, it could still be a build problem specific to your environment or a bug in that particular version.</p>";
        }
    } else {
        echo "<p style='color:orange; font-weight:bold;'>inotify extension is loaded, but <code>phpversion('inotify')</code> could not retrieve the version string. This is unusual and might indicate an improperly registered extension.</p>";
    }
} else {
    echo "<p style='color:red; font-weight:bold;'><b>inotify extension is NOT loaded.</b></p>";
    echo "<p>You need to install and enable it. For PHP 8.3, PECL package <code>inotify-3.0.0</code> is recommended: <code>sudo pecl install inotify-3.0.0</code></p>";
}

echo "<hr><p>To confirm this script is running under your web server (and not CLI), check the SAPI below:</p>";
echo "<p>PHP SAPI: <b>" . php_sapi_name() . "</b></p>";
echo "<p>PHP Version: <b>" . phpversion() . "</b></p>";

?>
