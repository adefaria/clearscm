<?php
require_once __DIR__ . "/clearscm.php";

$file   = $_REQUEST["file"] ?? "";
$action = $_REQUEST["action"] ?? "man";

// Redirect legacy repository/history actions directly to GitHub
if ($action === "repo" || $action === "tree") {
  $tree_path = trim ($_REQUEST["f"] ?? "", "/");
  $gh = "https://github.com/adefaria/clearscm" . ($tree_path !== "" ? "/tree/main/" . $tree_path : "");
  header ("Location: $gh");
  exit;
}

if ($action === "history" && $file !== "") {
  $git_rel = resolveSCMGitRelPath ($file);
  header ("Location: https://github.com/adefaria/clearscm/commits/main/$git_rel");
  exit;
}

// 1. Raw File Download
if ($action === "raw" && $file !== "") {
  $real = resolveSCMFilePath ($file);
  if (!$real) {
    http_response_code (404);
    die ("File not found: " . htmlspecialchars ($file));
  }
  $basename = basename ($real);
  header ("Content-Type: text/plain; charset=utf-8");
  header ("Content-Disposition: attachment; filename=\"$basename\"");
  header ("Content-Length: " . filesize ($real));
  readfile ($real);
  exit;
}

// 2. Tarball Archive Download (clearlib.tar.gz / clearenv.tar.gz)
if ($action === "archive") {
  $target = $_REQUEST["target"] ?? "";
  if ($target === "clearlib") {
    $filename = "clearlib.tar.gz";
    $items = "lib etc/mail.conf";
  } elseif ($target === "clearenv") {
    $filename = "clearenv.tar.gz";
    $items = "rc";
  } else {
    http_response_code (400);
    die ("Unknown archive target");
  }
  header ("Content-Type: application/gzip");
  header ("Content-Disposition: attachment; filename=\"$filename\"");
  passthru ("tar -C /opt/clearscm --exclude='.git' --exclude='CVS' -zcf - $items 2>/dev/null");
  exit;
}

$page_title = "ClearSCM: " . htmlspecialchars ($file);
?>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
   "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
  <title><?php echo $page_title; ?></title>
  <link rel="SHORTCUT ICON" href="/clearscm/favicon.ico" type="image/x-icon">
  <?php menu_css (); ?>
</head>

<body id="homepage">
<?php heading (); ?>

<div id="page">
  <div id="content">
    <?php
    if ($action === "source" && $file !== "") {
      display_code ($file, true);
    } elseif ($file !== "") {
      scm_man ($file, true);
    } else {
      print "<p>No file specified.</p>";
    }
    ?>
  </div>
  <?php copyright (); ?>
</div>

</body>
</html>
