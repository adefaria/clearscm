package TriggerUtils;
  require (Exporter);
  @ISA = qw (Exporter);

  @EXPORT = qw (clearmsg clearlog clearlogmsg);

  BEGIN {
    $me = substr ($0, rindex ($0, "\\") + 1);

    # Set logfile appropriately: We use ipconfig to get the current host's
    # IP address then determine whether we are in the US or China. If
    # neither then we fallback to using T:/Triggers/Logs/trigger.log
    my @ipconfig = grep (/IP Address/, `ipconfig`);
    my ($ipaddr) = ($ipconfig[0] =~ /(\d{1,3}\.\d{1,3}.\d{1,3}\.\d{1,3})/);

    # US is in the subnets of 192 and 172 while China is in the subnet of 10
    if ($ipaddr =~ /^192|^172/) {
      $logfile = "//sons-clearcase/Views/official/Tools/logs/trigger.log";
    } elsif ($ipaddr =~ /^10/) {
      $logfile = "//sons-cc/Views/official/Tools/logs/trigger.log";
    } else {
      die "Internal Error: Unable to the trigger.log!\n"
    } # if

    $user = $ENV {CLEARCASE_USER};
  } # BEGIN

  sub clearmsg {
    # Display a message to the user using clearprompt
    my ($message) = shift;

    `clearprompt proceed -type error -prompt "$message" -mask abort -default abort`;
  } # clearmsg

  sub clearlog {
    # Log a message to the log file
    my ($message) = shift;
    my ($date);

    ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime (time);
    $mon++;
    $year += 1900;
    $hour = "0" . $hour if $hour < 10;
    $min  = "0" . $min  if $min  < 10;
    $date = "$mon/$mday/$year\@$hour:$min";

    open (LOGFILE, ">>$logfile") || die "Unable to open logfile ($logfile)\n";

    print LOGFILE "$me: $date: $user: $message\n";

    close (LOGFILE);
  } # clearlog

  sub clearlogmsg {
    # Log message to log file then display it to user
    my ($message) = shift;

    clearlog ($message);
    clearmsg ($message);
  } # clearlogmsg

1;
