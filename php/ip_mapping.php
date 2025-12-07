<?php
// Define the path to the IP mapping file
$ipMappingFile = realpath(__DIR__ . '/../pm/ips');

/**
 * Loads the IP mapping from the specified file.
 *
 * @param string $filePath The path to the IP mapping file.
 * @return array An associative array where keys are IP addresses and values are their corresponding text descriptions.
 */
function loadIpMapping(string $filePath): array
{
    $ipMapping = [];

    if (file_exists($filePath) && is_readable($filePath)) {
        $lines = file($filePath, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);

        foreach ($lines as $line) {
            // Ignore comment lines
            if (strpos(trim($line), '#') === 0) {
                continue;
            }

            // Split the line into IP and text
            $parts = preg_split('/\s+/', $line, 2);

            if (count($parts) === 2) {
                $ipMapping[$parts[0]] = $parts[1];
            }
        }
    }

    return $ipMapping;
}

/**
 * Replaces the IP address with its corresponding text from the mapping, if available.
 *
 * @param string $ip The IP address to look up.
 * @param array $ipMapping The IP mapping array.
 * @return string The text description if found, otherwise the original IP address.
 */
function replaceIpWithText(string $ip, array $ipMapping): string
{
    return $ipMapping[$ip] ?? $ip;
}
?>