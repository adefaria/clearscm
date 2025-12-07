<?php
// Use __DIR__ and realpath() to construct the absolute path

require_once realpath(__DIR__ . '/ip_mapping.php');

$IPAddr = $_SERVER["REMOTE_ADDR"];
$download = isset($_GET['download']) ? $_GET['download'] : null;

// Define the filesystem path to the web server's document root.
// Use $_SERVER['DOCUMENT_ROOT'] if available and valid, otherwise fallback to a hardcoded path.
$fsWebRoot = isset($_SERVER['DOCUMENT_ROOT']) && is_dir($_SERVER['DOCUMENT_ROOT']) ? $_SERVER['DOCUMENT_ROOT'] : '/web';
const documentRoot = '/web/';

if (!$fsWebRoot) {
    // Fallback or error if a web root cannot be determined.
    die("Error: Could not determine web root filesystem path.");
}

function debug($message)
{
    echo "<font color='red'>$message</font><br>";
}

/**
 * Gets the HTTP address (URL) of the document root.
 *
 * @return string The HTTP address of the document root (e.g., "https://www.example.com/").
 */
function getDocumentRootHttpAddress(): string
{
    // Determine the protocol (http or https).
    $protocol = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off' ? 'https' : 'http';

    // Get the host (domain name or IP address).
    $host = $_SERVER['HTTP_HOST'] ?? null;

    if (!$host) {
        // Handle the case where the host is not available.
        // This might happen in CLI scripts or unusual server configurations.
        return "Unable to determine document root HTTP address."; // Or handle as an error
    }

    // Construct the document root HTTP address.
    $documentRootHttpAddress = $protocol . '://' . $host . '/';

    return $documentRootHttpAddress;
}

/**
 * Logs image access to a file.
 * @param string $filePath The path of the image being accessed.
 */
function logImageAccess(string $filePath): void
{
    $ipAddress = $_SERVER['REMOTE_ADDR'] ?? 'UNKNOWN';
    $timestamp = date('Y-m-d H:i:s');
    $logMessage = "[$timestamp] IP: $ipAddress, File: $filePath\n";
    // Append to the log file
    file_put_contents('/web/php/image_access.log', $logMessage, FILE_APPEND);
}

/**
 * Generates a full URL from a relative URL and the current request context.
 *
 * @param string $relativeUrl The relative URL (e.g., "path/to/resource", "../another/resource", "resource.php?param=value").
 * @return string The full URL, or null if the full URL could not be determined.
 */
function getFullUrl(string $relativeUrl): ?string
{
    // Check if the input is already a full URL.
    if (preg_match('/^(http|https):\/\//', $relativeUrl)) {
        return $relativeUrl; // It's already a full URL.
    }

    // Check if the relative URL starts with a slash
    if (!empty($relativeUrl) && $relativeUrl[0] === '/') {
        return getDocumentRootHttpAddress() . ltrim($relativeUrl, '/');
    } else {
        // If it doesn't start with a slash, append it to the referrer URL
        if (isset($_SERVER['HTTP_REFERER'])) {
            return $_SERVER['HTTP_REFERER'] . $relativeUrl;
        }
        // Fallback if referrer is not available
        return getDocumentRootHttpAddress() . $relativeUrl;
    }
}

// --- Main ---
$URL = "";
$path = null; // Initialize $path to null

// Load the IP mapping
$ipMapping = loadIpMapping($ipMappingFile);

$displayValue = replaceIpWithText($IPAddr, $ipMapping);

if (isset($_GET['u'])) {
    $URL = $_GET['u'];

    // The 'u' parameter is expected to be the web-relative path starting with '/'
    if (empty($URL) || $URL[0] !== '/') {
        header("HTTP/1.0 400 Bad Request");
        echo "Invalid URL format. It must be a web-relative path starting with '/'.";
        exit;
    }

    // Construct the potential filesystem path by prepending the document root
    $potentialPath = $fsWebRoot . $URL;

    // Resolve the real path to prevent directory traversal (e.g., /../../etc/passwd)
    $realPath = realpath($potentialPath);
    $path = $realPath;

    // Check if the download parameter is set in $_GET and handle it first
    if (isset($download)) {
        // Set headers for file download.
        header('Content-Description: File Transfer');
        header('Content-Type: application/octet-stream');
        $filename = urldecode($_GET['download']);
        $trimmedFilename = substr($filename, 1, -1);
        header('Content-Disposition: attachment; filename="' . trim($trimmedFilename) . '"');
        header('Expires: 0');
        header('Cache-Control: must-revalidate');
        header('Pragma: public');
        header('Content-Length: ' . filesize($path));
        readfile($path);
        exit; // Important: Stop further execution after sending the file
    }

    // Security check: prevent directory traversal
    if (strpos($URL, '..') !== false) {
        http_response_code(400);
        die('Invalid file path: directory traversal detected.');
    }

    // Security check: Ensure the resolved path exists, is a file, and is within the document root
    if ($realPath === false || !is_file($realPath) || strpos($realPath, $fsWebRoot) !== 0) {
        header("HTTP/1.0 404 Not Found");
        echo "File not found or access denied.";
        exit;
    }


    // Now, $path holds the correct absolute filesystem path (e.g., /opt/defaria.com/web/tmp/Something.mp3)
    // And $URL holds the correct web-relative path (e.g., /web/tmp/Something.mp3)
    // The rest of the script can proceed using $path for file operations and $URL for display/logging.

} else {
}


$msg = '<html><body>';

$fullURL = getFullUrl($URL);

if ($displayValue == $IPAddr) {
    $msg .= "<h1>Somebody accessed $URL</h1>";
} else {
    $msg .= "<h1>$displayValue accessed $URL</h1>";
}

$msg .= "<p>Full URL: $fullURL</p>";
$msg .= "<p>Here's what I know about them:</p>";

$me = false;
$myip = '75.80.5.95';

if (isset($_SERVER['HTTP_REFERER']) && !empty($_SERVER['HTTP_REFERER'])) {
    $msg .= "HTTP_REFERER: " . htmlspecialchars($_SERVER['HTTP_REFERER']) . "<br>";
} else {
    $msg .= "HTTP_REFERER: URL Typed<br>";
}

foreach ($_SERVER as $key => $value) {
    if (preg_match("/^REMOTE/", $key) || preg_match("/^HTTP_USER_AGENT/", $key)) {
        $msg .= "$key: $value<br>";

        if ($key == 'REMOTE_ADDR') {
            // Skip me...
            if ($value == $myip) {
                $me = true;
                break;
            } // if

            exec("whois $value", $output, $result);

            foreach ($output as $line) {
                $msg .= "$line<br>";
            } // foreach
        } // if
    } // if
} // foreach

if (!$me) {
    $histfilePath = '/web/pm/.history';
    $histfile = @fopen($histfilePath, 'a');
    if ($histfile === false) {
        $error = error_get_last();
        $errorMessage = "Could not open history file for writing.";
        $errorDetails = "Error: " . ($error['message'] ?? 'Unknown error');
        
        // Output an error page to the user
        header("HTTP/1.1 500 Internal Server Error");
        echo "<html><head><title>Server Error</title></head><body>";
        echo "<h1>We encountered an issue</h1>";
        echo "<p>There was a problem logging your request. Please email the following details to <a href='mailto:Andrew@DeFaria.com'>Andrew@DeFaria.com</a></p>";
        echo "<p><strong>URL Accessed:</strong> " . htmlspecialchars($URL) . "</p>";
        echo "<p><strong>Error Details:</strong> " . htmlspecialchars($errorMessage) . " (" . htmlspecialchars($errorDetails) . ")</p>";
        echo "</body></html>";
        exit;
    } else {
        $date = date(DATE_RFC822);
        $access = $download ? "downloaded" : "accessed";
        fwrite($histfile, "$_SERVER[REMOTE_ADDR] $access $URL $date\n");
        fclose($histfile);
    }

    $msg .= '</body></html>';

    $headers = "MIME-Version: 1.0\r\n";
    $headers .= "Content-type: text/html; charset=iso-8859-1\r\n";
    $headers .= "From: WebMonitor <WebMonitor@DeFaria.com>";

    if ($displayValue == $IPAddr) {
        $subject = "Somebody just ";
    } else {
        $subject = "$displayValue just ";
    } // if

    if ($download) {
        $subject .= "downloaded $URL";
    } else {
        $subject .= "accessed $URL";
    } // if

    // Replace IP address in the email subject and body with text from the mapping
    $displayIP = replaceIpWithText($IPAddr, $ipMapping);
    $subject = str_replace($IPAddr, $displayIP, $subject);
    $msg = str_replace("REMOTE_ADDR: $_SERVER[REMOTE_ADDR]", "REMOTE_ADDR: $displayIP", $msg);

    mail("andrew@defaria.com", $subject, $msg, $headers);
} else {
    $msg .= '</body></html>';

    $headers = "MIME-Version: 1.0\r\n";
    $subject = "";

    mail("andrew@defaria.com", $subject, $msg, $headers);
} // if

// Determine if it's a video or audio file based on extension
$fileExtension = pathinfo($URL, PATHINFO_EXTENSION); // Use $URL for extension check as it's the web path

if (in_array(strtolower($fileExtension), ['mp4', 'webm', 'ogg', 'mkv'])) {
    header("Location: /php/videoplayback.php?video=" . urlencode($URL));
} elseif (in_array(strtolower($fileExtension), ['m4a', 'mp3', 'wav', 'ogg'])) {
    header("Location: /php/audioplayback.php?audio=" . urlencode($URL));
} else {
    // For all other file types, serve them directly with the correct MIME type.
    // This handles images and other general file types.
    $finfo = finfo_open(FILEINFO_MIME_TYPE);
    $mime_type = finfo_file($finfo, $path);
    finfo_close($finfo);
    header('Content-Type: ' . $mime_type);
    header('Content-Length: ' . filesize($path));
    readfile($path);
}

exit;
?>