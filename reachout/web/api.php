<?php
/**
 * ClearSCM Reachout Administration API
 * Provides endpoints for managing contacts, scheduling, state, and executions.
 */

header('Content-Type: application/json; charset=utf-8');
header('X-Content-Type-Options: nosniff');
date_default_timezone_set('America/Los_Angeles');

$base_dir = dirname(__DIR__);
$contacts_file = $base_dir . '/data/contacts.json';
$state_file = $base_dir . '/data/reachout_state.json';
$config_file = $base_dir . '/etc/reachout.conf';
$bin_reachout = '/opt/clearscm/bin/reachout';
if (!file_exists($bin_reachout)) {
    $bin_reachout = $base_dir . '/bin/reachout';
}

function send_json($data, $code = 200) {
    http_response_code($code);
    echo json_encode($data, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
    exit;
}

function send_error($msg, $code = 400) {
    send_json(['success' => false, 'error' => $msg], $code);
}

function load_json($file, $default = []) {
    if (!file_exists($file) || !is_readable($file)) {
        return $default;
    }
    $content = file_get_contents($file);
    if ($content === false || trim($content) === '') {
        return $default;
    }
    $data = json_decode($content, true);
    return is_array($data) ? $data : $default;
}

function save_json($file, $data) {
    $dir = dirname($file);
    if (!is_dir($dir)) {
        mkdir($dir, 0775, true);
    }
    $json = json_encode($data, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
    $res = file_put_contents($file, $json, LOCK_EX);
    if ($res === false) {
        return false;
    }
    chmod($file, 0664);
    return true;
}

$action = $_GET['action'] ?? $_POST['action'] ?? 'data';

// Load raw body for JSON requests
$request_payload = [];
$raw_input = file_get_contents('php://input');
if ($raw_input && trim($raw_input) !== '') {
    $decoded = json_decode($raw_input, true);
    if (is_array($decoded)) {
        $request_payload = $decoded;
    }
}
$params = array_merge($_GET, $_POST, $request_payload);

switch ($action) {
    case 'data':
        $contacts = load_json($contacts_file, []);
        $state = load_json($state_file, ['targets' => []]);
        $targets = $state['targets'] ?? [];

        // Detect current environment
        $host = strtolower(gethostname());
        $env = (strpos($host, 'earth') !== false) ? 'staging' : ((strpos($host, 'defaria') !== false || strpos($host, 'cloud') !== false) ? 'production' : 'staging');

        // Compile stats
        $now = time();
        $total_contacts = count($contacts);
        $active_count = 0;
        $paused_count = 0;
        $ready_now = 0;
        $staggered = 0;

        foreach ($contacts as $c) {
            $id = $c['id'];
            $st = $targets[$id] ?? null;
            $current_status = $st['status'] ?? ($c['status'] ?? 'active');
            if ($current_status === 'active') {
                $active_count++;
                $next_epoch = $st['next_run_epoch'] ?? 0;
                if ($next_epoch <= $now) {
                    $ready_now++;
                } else {
                    $staggered++;
                }
            } elseif ($current_status === 'paused') {
                $paused_count++;
            }
        }

        send_json([
            'success' => true,
            'environment' => $env,
            'hostname' => $host,
            'contacts' => $contacts,
            'targets' => $targets,
            'stats' => [
                'total' => $total_contacts,
                'active' => $active_count,
                'paused' => $paused_count,
                'ready_now' => $ready_now,
                'staggered' => $staggered,
            ],
            'server_time' => [
                'epoch' => $now,
                'formatted' => date('Y-m-d H:i:s'),
                'timezone' => date_default_timezone_get(),
            ]
        ]);
        break;

    case 'save_contact':
        $id = trim($params['id'] ?? '');
        $venue = trim($params['venue'] ?? '');
        $contact = trim($params['contact'] ?? '');
        $email = trim($params['email'] ?? '');
        $phone = trim($params['phone'] ?? '');
        $web = trim($params['web'] ?? '');
        $template = trim($params['template'] ?? 'rockready_club');
        $policy = trim($params['policy'] ?? 'passive');
        $status = trim($params['status'] ?? 'active');
        $schedule_date = trim($params['schedule_date'] ?? '');

        if ($venue === '' || $email === '') {
            send_error('Venue name and Email address are required.');
        }

        if ($id === '') {
            // Generate clean slug ID from venue name
            $id = strtolower(preg_replace('/[^a-zA-Z0-9]+/', '-', $venue));
            $id = trim($id, '-');
        }

        $contacts = load_json($contacts_file, []);
        $found_index = -1;
        foreach ($contacts as $idx => $c) {
            if ($c['id'] === $id) {
                $found_index = $idx;
                break;
            }
        }

        $contact_record = [
            'id' => $id,
            'venue' => $venue,
            'contact' => $contact,
            'email' => $email,
            'web' => $web,
            'phone' => $phone,
            'template' => $template,
            'policy' => $policy,
            'status' => $status,
        ];

        if ($found_index >= 0) {
            $contacts[$found_index] = array_merge($contacts[$found_index], $contact_record);
        } else {
            $contacts[] = $contact_record;
        }

        if (!save_json($contacts_file, $contacts)) {
            send_error('Failed to write to contacts.json. Check file permissions.');
        }

        // Handle initial schedule date if provided
        $state = load_json($state_file, ['targets' => []]);
        if (!isset($state['targets'][$id])) {
            $state['targets'][$id] = [
                'id' => $id,
                'attempts' => 0,
                'history' => [],
                'status' => $status,
            ];
        }
        $state['targets'][$id]['status'] = $status;

        if ($schedule_date !== '') {
            $epoch = strtotime($schedule_date);
            if ($epoch !== false) {
                $state['targets'][$id]['next_run_epoch'] = $epoch;
                $state['targets'][$id]['next_run_date'] = date('Y-m-d H:i:s', $epoch);
            }
        } elseif (!isset($state['targets'][$id]['next_run_epoch'])) {
            // Leave as ready
            $state['targets'][$id]['next_run_epoch'] = null;
            $state['targets'][$id]['next_run_date'] = null;
        }

        $state['targets'][$id]['updated_date'] = date('Y-m-d H:i:s');
        save_json($state_file, $state);

        send_json([
            'success' => true,
            'message' => 'Contact saved successfully.',
            'contact' => $contact_record,
            'target' => $state['targets'][$id],
        ]);
        break;

    case 'delete_contact':
        $id = trim($params['id'] ?? '');
        if ($id === '') {
            send_error('Target ID is required for deletion.');
        }

        $contacts = load_json($contacts_file, []);
        $new_contacts = [];
        $found = false;
        foreach ($contacts as $c) {
            if ($c['id'] === $id) {
                $found = true;
                continue;
            }
            $new_contacts[] = $c;
        }

        if (!$found) {
            send_error("Contact '$id' not found.");
        }

        save_json($contacts_file, $new_contacts);

        // Optionally remove or mark deleted in state
        $state = load_json($state_file, ['targets' => []]);
        if (isset($state['targets'][$id])) {
            unset($state['targets'][$id]);
            save_json($state_file, $state);
        }

        send_json(['success' => true, 'message' => "Target '$id' deleted."]);
        break;

    case 'set_status':
        $id = trim($params['id'] ?? '');
        $status = trim($params['status'] ?? 'active');
        $reason = trim($params['reason'] ?? '');

        if ($id === '') {
            send_error('Target ID is required.');
        }

        $valid_statuses = ['active', 'paused', 'booked', 'completed', 'declined'];
        if (!in_array($status, $valid_statuses, true)) {
            send_error("Invalid status '$status'.");
        }

        // Update in contacts.json
        $contacts = load_json($contacts_file, []);
        foreach ($contacts as &$c) {
            if ($c['id'] === $id) {
                $c['status'] = $status;
                break;
            }
        }
        save_json($contacts_file, $contacts);

        // Update in reachout_state.json
        $state = load_json($state_file, ['targets' => []]);
        if (!isset($state['targets'][$id])) {
            $state['targets'][$id] = [
                'id' => $id,
                'attempts' => 0,
                'history' => [],
            ];
        }
        $state['targets'][$id]['status'] = $status;
        if ($reason !== '') {
            $state['targets'][$id]['status_reason'] = $reason;
        }
        $state['targets'][$id]['updated_date'] = date('Y-m-d H:i:s');
        save_json($state_file, $state);

        send_json([
            'success' => true,
            'message' => "Target '$id' status updated to '$status'.",
            'target' => $state['targets'][$id],
        ]);
        break;

    case 'schedule':
        $id = trim($params['id'] ?? '');
        $date_input = trim($params['date'] ?? '');

        if ($id === '') {
            send_error('Target ID is required.');
        }

        $epoch = null;
        $date_str = null;

        if ($date_input !== '' && $date_input !== 'now' && $date_input !== 'immediate') {
            $epoch = is_numeric($date_input) ? intval($date_input) : strtotime($date_input);
            if ($epoch === false || $epoch <= 0) {
                send_error("Invalid date string '$date_input'. Use 'YYYY-MM-DD HH:MM:SS'.");
            }
            $date_str = date('Y-m-d H:i:s', $epoch);
        } else {
            // Immediate / ready now
            $epoch = null;
            $date_str = null;
        }

        $state = load_json($state_file, ['targets' => []]);
        if (!isset($state['targets'][$id])) {
            $state['targets'][$id] = [
                'id' => $id,
                'attempts' => 0,
                'history' => [],
                'status' => 'active',
            ];
        }

        $state['targets'][$id]['next_run_epoch'] = $epoch;
        $state['targets'][$id]['next_run_date'] = $date_str;
        $state['targets'][$id]['updated_date'] = date('Y-m-d H:i:s');
        save_json($state_file, $state);

        send_json([
            'success' => true,
            'message' => $epoch ? "Scheduled '$id' for $date_str." : "Target '$id' marked ready for next run.",
            'target' => $state['targets'][$id],
        ]);
        break;

    case 'preview':
        $id = trim($params['id'] ?? '');
        if ($id === '') {
            send_error('Target ID is required.');
        }

        $contacts = load_json($contacts_file, []);
        $target = null;
        foreach ($contacts as $c) {
            if ($c['id'] === $id) {
                $target = $c;
                break;
            }
        }
        if (!$target) {
            send_error("Target '$id' not found in contacts.");
        }

        $template_name = $target['template'] ?? 'rockready_club';
        $html_file = "$base_dir/templates/$template_name.html";
        $txt_file = "$base_dir/templates/$template_name.txt";

        $html = file_exists($html_file) ? file_get_contents($html_file) : '<p>No HTML template found.</p>';
        $txt = file_exists($txt_file) ? file_get_contents($txt_file) : 'No Plain text template found.';

        // Prepare preview replacements
        $replacements = [
            'Contact' => htmlspecialchars($target['contact'] ?: 'Booking Manager'),
            'Venue' => htmlspecialchars($target['venue'] ?: 'Venue'),
            'Email' => htmlspecialchars($target['email'] ?: ''),
            'BandName' => 'Rock Ready',
            'SiteUrl' => 'https://rockready.band',
            'PhotoUrl' => 'https://rockready.band/RockReady.band.jpg',
            'VideosUrl' => 'https://rockready.band/videos',
            'PhotosUrl' => 'https://rockready.band/gallery',
            'SenderName' => 'Andrew DeFaria',
            'SenderEmail' => 'Andrew@DeFaria.com',
            'SenderPhone' => '(408) 596-4937',
            'UpcomingShowsHtml' => '<div style="background:#222;color:#eee;padding:10px;border-radius:4px;"><em>Live shows feed pulled dynamically at dispatch time</em></div>',
            'UpcomingShowsTxt' => "Live upcoming shows feed\n",
            'AttemptNumber' => '1',
            'TicketId' => 'REQ-8492',
            'SystemAffected' => 'Production Infrastructure',
            'Severity' => 'High',
            'Issue' => 'Venue Booking Inquiry',
            'Message' => 'Inquiring regarding band booking schedule.',
            'Reference' => '',
        ];

        foreach ($replacements as $key => $val) {
            $html = preg_replace('/\{\{\s*' . preg_quote($key, '/') . '\s*\}\}/', $val, $html);
            $txt = preg_replace('/\{\{\s*' . preg_quote($key, '/') . '\s*\}\}/', $val, $txt);
        }
        // Remove remaining tokens
        $html = preg_replace('/\{\{\s*[\w\.]+\s*\}\}/', '', $html);
        $txt = preg_replace('/\{\{\s*[\w\.]+\s*\}\}/', '', $txt);

        send_json([
            'success' => true,
            'target' => $target,
            'template' => $template_name,
            'html' => $html,
            'text' => $txt,
        ]);
        break;

    case 'run':
        $dry_run = !empty($params['dry_run']);
        $cmd = escapeshellcmd($bin_reachout) . " run -v";
        if ($dry_run) {
            $cmd .= " --dry-run";
        }

        // Execute reachout command
        $output = [];
        $exit_code = 0;
        exec("$cmd 2>&1", $output, $exit_code);

        send_json([
            'success' => ($exit_code === 0),
            'command' => $cmd,
            'exit_code' => $exit_code,
            'dry_run' => $dry_run,
            'output' => implode("\n", $output),
            'timestamp' => date('Y-m-d H:i:s'),
        ]);
        break;

    case 'get_templates':
        $template_dir = $base_dir . '/templates';
        $templates = [];
        if (is_dir($template_dir)) {
            $files = scandir($template_dir);
            $names = [];
            foreach ($files as $f) {
                if ($f === '.' || $f === '..') continue;
                if (preg_match('/^([a-zA-Z0-9_\-]+)\.(html|txt)$/', $f, $m)) {
                    $names[$m[1]] = true;
                }
            }
            foreach (array_keys($names) as $tname) {
                $html_file = "$template_dir/$tname.html";
                $txt_file = "$template_dir/$tname.txt";
                $html_exists = file_exists($html_file);
                $txt_exists = file_exists($txt_file);
                $mtime = max(
                    $html_exists ? filemtime($html_file) : 0,
                    $txt_exists ? filemtime($txt_file) : 0
                );
                $templates[] = [
                    'name' => $tname,
                    'has_html' => $html_exists,
                    'has_txt' => $txt_exists,
                    'html_size' => $html_exists ? filesize($html_file) : 0,
                    'txt_size' => $txt_exists ? filesize($txt_file) : 0,
                    'modified_date' => $mtime ? date('Y-m-d H:i:s', $mtime) : '',
                ];
            }
        }
        usort($templates, fn($a, $b) => strcmp($a['name'], $b['name']));
        send_json(['success' => true, 'templates' => $templates]);
        break;

    case 'get_template':
        $name = trim($params['name'] ?? '');
        if ($name === '' || !preg_match('/^[a-zA-Z0-9_\-]+$/', $name)) {
            send_error('Invalid template name.');
        }
        $template_dir = $base_dir . '/templates';
        $html_file = "$template_dir/$name.html";
        $txt_file = "$template_dir/$name.txt";
        
        $html = file_exists($html_file) ? file_get_contents($html_file) : '';
        $txt = file_exists($txt_file) ? file_get_contents($txt_file) : '';
        
        send_json([
            'success' => true,
            'name' => $name,
            'html' => $html,
            'txt' => $txt,
        ]);
        break;

    case 'save_template':
        $name = trim($params['name'] ?? '');
        $orig_name = trim($params['original_name'] ?? '');
        $html = $params['html'] ?? '';
        $txt = $params['txt'] ?? '';
        
        if ($name === '') {
            send_error('Template name cannot be empty.');
        }
        $name = strtolower(preg_replace('/[^a-zA-Z0-9_\-]+/', '_', $name));
        $name = trim($name, '_');
        
        $template_dir = $base_dir . '/templates';
        if (!is_dir($template_dir)) {
            mkdir($template_dir, 0775, true);
        }
        
        if ($orig_name !== '' && $orig_name !== $name) {
            if (file_exists("$template_dir/$orig_name.html")) unlink("$template_dir/$orig_name.html");
            if (file_exists("$template_dir/$orig_name.txt")) unlink("$template_dir/$orig_name.txt");
        }
        
        file_put_contents("$template_dir/$name.html", $html, LOCK_EX);
        file_put_contents("$template_dir/$name.txt", $txt, LOCK_EX);
        chmod("$template_dir/$name.html", 0664);
        chmod("$template_dir/$name.txt", 0664);
        
        send_json(['success' => true, 'message' => "Template '$name' saved successfully.", 'name' => $name]);
        break;

    case 'delete_template':
        $name = trim($params['name'] ?? '');
        if ($name === '' || !preg_match('/^[a-zA-Z0-9_\-]+$/', $name)) {
            send_error('Invalid template name.');
        }
        $template_dir = $base_dir . '/templates';
        $html_file = "$template_dir/$name.html";
        $txt_file = "$template_dir/$name.txt";
        
        $deleted = false;
        if (file_exists($html_file)) {
            unlink($html_file);
            $deleted = true;
        }
        if (file_exists($txt_file)) {
            unlink($txt_file);
            $deleted = true;
        }
        
        if (!$deleted) {
            send_error("Template '$name' not found.");
        }
        send_json(['success' => true, 'message' => "Template '$name' deleted."]);
        break;

    default:
        send_error("Unknown action '$action'.");
        break;
}
