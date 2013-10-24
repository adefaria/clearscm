#!/usr/bin/perl

=pod

=head1 NAME $RCSfile: cleartasks.pl,v $

Scrub Clearadm records

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision

$Revision: 1.25 $

=item Created:

Sun Jan  2 19:40:28 EST 2011

=item Modified:

$Date: 2013/06/02 18:47:26 $

=back

=head1 SYNOPSIS

 Usage cleartasks.pl: [-u|sage] [-ve|rbose] [-deb|ug]

 Where:
   -u|sage:     Displays usage
 
   -v|erbose:   Be verbose
   -de|bug:     Output debug messages
   
   -da|emon:    Run in daemon mode (Default: yes)
   -p|idfile:   File to be created with the pid written to it (Default:
                cleartasks.pid). Note: pidfile is only written if -daemon is
                specified.
                       
=head1 DESCRIPTION

Examine the Clearadm schedule and perform the tasks required.

=cut

use strict;
use warnings;

use FindBin;
use Getopt::Long;

use lib "$FindBin::Bin/lib", "$FindBin::Bin/../lib";

use Clearadm;
use Clearexec;
use DateUtils;
use Display;
use TimeUtils;
use Utils;

my $VERSION  = '$Revision: 1.25 $';
  ($VERSION) = ($VERSION =~ /\$Revision: (.*) /);

my $logfile = "$Clearadm::CLEAROPTS{CLEARADM_LOGDIR}/$FindBin::Script.log";           
my $pidfile = "$Clearadm::CLEAROPTS{CLEARADM_RUNDIR}/$FindBin::Script.pid";
my $daemon  = 1;

# Augment PATH with $Clearadm::CLEAROPTS{CLEARADM_BASE}
$ENV{PATH} .= ":$Clearadm::CLEAROPTS{CLEARADM_BASE}";

my ($clearadm, $clearexec);

sub HandleSystemNotCheckingIn (%) {
  my (%system) = @_;
   
  my $startTime = time;
  
  my $message = "Unable to connect to system $system{name}:$system{port}";

  my %runlog = (
    task     => 'System checkin',
    started  => Today2SQLDatetime,
    status   => 1,
    message  => $message,
    system   => $system{name},
  );

  my ($err, $msg, $lastid) = $clearadm->AddRunlog (%runlog);
  
  $clearadm->Error ("Unable to add to runlog (Status: $err)\n$msg") if $err;
   
  # Check to see if we should notify anybody about this non-responding system
  my %notification = $clearadm->GetNotification ('System checkin'); 
          
  my $when            = Today2SQLDatetime;
  my $nomorethan      = lc $notification{nomorethan};
  my $systemLink      = $Clearadm::CLEAROPTS{CLEARADM_WEBBASE};
     $systemLink     .= "/systemdetails.cgi?system=$system{name}";
  my $runlogLink      = $Clearadm::CLEAROPTS{CLEARADM_WEBBASE};
     $runlogLink     .= "/runlog.cgi?id=$lastid";
   my $subject         = "System is not responding (Is clearagent running?)";
     $message = <<"END";      
<center>
<h1><font color="red">Alert</font> System not responding!</h1>
</center>

<p>On $when the system <a href="$systemLink">$system{name}</a> was <a 
href="$runlogLink">not responding</a> to clearagent requests. This can happen if
clearagent is not setup and running on the system.</p> 
END
     
  $clearadm->Notify (
    $notification{name},
    $subject,
    $message,
    'System Checkin',
    $system{name},
    undef,
    $lastid,
  );
              
  verbose "$system{name}: $subject";
  
  return;
} # HandleSystemNotCheckingIn

sub SystemsCheckin () {
  foreach ($clearadm->FindSystem) {
    my %system = %$_;
    
    next if $system{active} eq 'false';
    
    verbose "Contacting system $system{name}:$system{port}";
    
    my $startTime = time;
    
    my $status = $clearexec->connectToServer (
      $system{name},
      $system{port}
    );
    
    unless ($status) {
      HandleSystemNotCheckingIn %system;
      next;
    } # unless
    
    $clearexec->disconnectFromServer;
    
    verbose 'Successfully checked in with system: '
          . "$system{name}:$system{port}";
    
    display __FILE__ . " DEBUG: System undefined 1" unless $system{name};
    $clearadm->UpdateSystem (
      $system{name},
      (lastheardfrom => Today2SQLDatetime)
    );
  
    $clearadm->ClearNotifications ($system{name})
      if $system{notification} and $system{notification} eq 'Heartbeat';
  } # foreach
  
  return;
} # SystemsCheckin

sub UpdateRunlog ($$$$) {
  my ($status, $startTime, $task, $output) = @_;
  
  my %runlog = (
    task    => $$task{name},
    system  => $$task{system},
    started => Today2SQLDatetime,
  );

  $runlog{status} = $status;
    
  if ($status == 0) {
    if (@$output) {
      $runlog{message} = join "\n", @$output;
    } else {
      $runlog{message}  = 'Successful execution of ';
      $runlog{message} .= "$$task{name}: $$task{command}";
    } # if
  } else {
    if (@$output) {
      $runlog{message} = join "\n", @$output;
    } else {
      $runlog{message}  = 'Unable to execute ';
      $runlog{message} .= "$$task{name}: $$task{command} ";
      $runlog{message} .= join (' ', @$output);
    } # if
  } # if
    
  my ($err, $msg, $lastid) = $clearadm->AddRunlog (%runlog);
    
  $clearadm->Error ($msg, $err) if $err;

  return $lastid;
} # UpdateRunlog

sub MakeSystemLink ($) {
  my ($system) = @_;
  
  return "$Clearadm::CLEAROPTS{CLEARADM_WEBBASE}/systemdetails.cgi?system="
       . $system;
} # MakeSystemLink

sub MakeLoadavgLink ($) {
  my ($system) = @_;

  return "$Clearadm::CLEAROPTS{CLEARADM_WEBBASE}/plot.cgi?type=loadavg&system="
       . "$system&scaling=Hour&points=24";
} # MakeLoadavgLink

sub ProcessLoadavgErrors ($$$$@) {
  # TODO: Also need to handle the case where the error was something other
  # than "Load average over threshold". Perhaps by having different return
  # status. Also, runlog entry #22169 never reported!
  my ($notification, $task, $system, $lastid, @output) = @_;
  
  my $when = Today2SQLDatetime;
  
  foreach (@output) {
    # We need to log this output. Write it to STDOUT
    display $_;

    my ($subject, $message, $currLoadavg, $threshold, $systemLink, $loadavgLink);

    if (/System: (\w+) Loadavg (\d+\.\d+) Threshold (\d+\.\d+)/) {
      $system       = $1;
      $currLoadavg  = $2;
      $threshold    = $3;
      $systemLink   = MakeSystemLink $system;
      $loadavgLink  = MakeLoadavgLink $system;
      $subject      = "Load average of $currLoadavg exceeds threshold ";
      $subject     .= "($threshold)";
      $message      = <<"END";      
<center>
<h1><font color="red">Alert</font> Load Average is over the threshold!</h1>
</center>

<p>On $when the system <a href="$systemLink">$system</a>'s load avg
(<a href="$loadavgLink">$currLoadavg</a>) had exceeded the threshold set for
this system ($threshold).</p> 
END
    } elsif (/ERROR.*system\s+(\S+):/) {
      $system     = $1;
      $systemLink = MakeSystemLink $system;
      $subject    = "Error trying to obtain Loadavg";
      $message    = <<"END";
<center>
<h1><font color="red">Alert</font> Unable to obtain Loadavg!</h1>
</center>

<p>On $when we were unable to obtain the Loadavg for
system <a href="$systemLink">$system</a>.</p>

<p>The following was the error message:</p>
<pre>$_</pre>
END
    } else {
      $message = <<"END";
<p>On $when on the system $system, we were unable to parse the Loadavg output. This is what we saw:</p>

<pre>
END
      $message .= join "\n", @output;
      $message .= "</pre>";
      $clearadm->Error ($message, -1);
      
      last;
    } # if

    $clearadm->Notify (
      $notification,
      $subject,
      $message,
      $task,
      $system,
      undef,
      $lastid,
    );
  } # foreach
  
  return;
} # ProcessLoadAvgErrors

sub ProcessFilesystemErrors ($$$$@) {
  # TODO: Also need to handle the case where the error was something other
  # than "Filesystem over threshold". Perhaps by having different return
  # status.
  my ($notification, $task, $system, $lastid, @output) = @_;

  my $when = Today2SQLDatetime;

  my %system;
  
  foreach (@output) {
    # We need to log this output. Write it to STDOUT
    display $_;
    
    if (/System:\s*(\S+)\s*Filesystem:\s*(\S+)\s*Used:\s*(\d+\.\d+)%\s*Threshold:\s*(\d+)/) {
      my %fsinfo = (
        filesystem => $2,
        usedPct    => $3,
        threshold  => $4
      );
      
      if ($system{$1}) {
         $system{$1} = [$system{$1}, \%fsinfo];
      } else {
        $system{$1} = \%fsinfo;
      } # if
    } # if
  } # foreach
   
  foreach my $systemName (keys %system) {
    my @fsinfo;
    
    if (ref $system{$systemName} eq 'HASH') {
       push @fsinfo, $system{$systemName};
    } else {
       push @fsinfo, @{$system{$systemName}};
    } # if

    my $systemLink = MakeSystemLink ($systemName);
    my $subject    = 'Filesystem has exceeded threshold';
    my $message = <<"END";      
<center>
<h1><font color="red">Alert</font> Filesystem is over the threshold!</h1>
</center>

<p>On $when the following filesystems on <a href="$systemLink">$systemName</a>
were over their threshold.</p>

<ul>
END
    foreach (@fsinfo) {
      my %fsinfo = %{$_};
      my $filesystemLink  = $Clearadm::CLEAROPTS{CLEARADM_WEBBASE};
         $filesystemLink .= "/plot.cgi?type=filesystem&system=$systemName";
         $filesystemLink .= "&filesystem=$fsinfo{filesystem}";
         $filesystemLink .= '&scaling=Day&points=7';
      $message .= "<li>Filesystem <a href=\"$filesystemLink\">";
      $message .= "$fsinfo{filesystem}</a> is $fsinfo{usedPct}% full. Threshold is ";
      $message .= "$fsinfo{threshold}%</li>";
    } # foreach
      
    $message .= "</ul>";
    
    $clearadm->Notify (
      $notification,
      $subject,
      $message,
      $task,
      $systemName,
      undef,
      $lastid,
    );
  } # foreach
  
  return;
} # ProcessFilesystemErrors

sub NonZeroReturn ($$$$$$) {
  my ($system, $notification, $status, $lastid, $output, $task) = @_;

  my @output = @{$output};
  my %task   = %{$task};
  
  my $when = Today2SQLDatetime;
    
  my $subject      = "Non zero return from $task{command} "
                   . "executing on $system";
  my $taskLink     = $Clearadm::CLEAROPTS{CLEARADM_WEBBASE};
     $taskLink    .= "/tasks.cgi?task=$task{name}";
  my $similarLink  = $Clearadm::CLEAROPTS{CLEARADM_WEBBASE};
     $similarLink .= "/runlog.cgi?system=$task{system}"
                  . "&status=$status&"
                  . "&task=$task{name}";
  my $runlogLink   = $Clearadm::CLEAROPTS{CLEARADM_WEBBASE};
     $runlogLink  .= "/runlog.cgi?id=$lastid";
  my $message      = <<"END";
<center>
<h1><font color="red">Alert</font> Non zero status from script execution!</h1>
</center>

<p>On $when, while executing <a href="$taskLink">$task{name}</a> on
$task{system}, a non zero status of $status was returned. Here is the resulting
output:</p><blockquote><pre>
END

  $message .= join "\n", @output;
  $message .= <<"END";
</pre></blockquote>
<p>You may wish to examine the individual <a href="$runlogLink">runlog entry</a>
that caused this alert or a list of <a href="$similarLink">similar 
failures</a>.</p>
END

  $message .= "</pre></blockquote>";
  
  $clearadm->Notify (
    $notification,
    $subject,
    $message,
    $task,
    $system,
    undef,
    $lastid,
  );
  
  return;   
} # NonZeroReturn

sub ExecuteTask ($%) {
  my ($sleep, %task) = @_;
  
  my ($status, @output, %system, $subject, $message);

  verbose_nolf "Performing task $task{name}";
  
  my %notification = $clearadm->GetNotification ($task{notification});
       
  my $startTime = time;
  
  if ($task{system} =~ /localhost/i) {
    verbose " on localhost";
    ($status, @output) = Execute "$task{command} 2>&1";
  } else {
    %system = $clearadm->GetSystem ($task{system});
    
    verbose " on $system{name}";

    $status = $clearexec->connectToServer (
      $system{name},
      $system{port}
    );
    
    unless ($status) {
      $output[0] = "Unable to connect to system $system{name}:$system{port} to "
                 . "execute $task{command}";
      $status = -1;
    } else {
      ($status, @output) = $clearexec->execute ($task{command});
      
      $output[0] = "Unable to exec $task{command} on $system{name}"
        if $status == -1;
    } # unless
    
    $clearexec->disconnectFromServer;    
  } # if

  my $lastid = UpdateRunlog ($status, $startTime, \%task, \@output);
    
  if ($status != 0) {
    if ($notification{cond}
      and $notification{cond} =~ /non zero return/i) {
      NonZeroReturn (
        $system{name},
        $notification{name},
        $status,
        $lastid,
        \@output,
        \%task
      );
    } elsif ($notification{cond} =~ /loadavg over threshold/i) {
      ProcessLoadavgErrors ($notification{name}, $task{name}, $system{name}, $lastid, @output);
    } elsif ($notification{cond} =~ /filesystem over threshold/i) {
      ProcessFilesystemErrors ($notification{name}, $task{name}, $system{name}, $lastid, @output);
    } # if
  } else {
    $clearadm->ClearNotifications ($task{system});
  } # if
        
  my ($err, $msg) = $clearadm->UpdateSchedule (
    $task{schedulename},
    ( 'lastrunid' => $lastid ),
  );
    
  $clearadm->Error ($msg, $err) if $err;  
  
  $sleep -= time - $startTime;
  
  return $sleep;
} # ExecuteTask

# Main
GetOptions (
  'usage'     => sub { Usage },
  'verbose'   => sub { set_verbose },
  'debug'     => sub { set_debug },
  'daemon!'   => \$daemon,
  'pidfile=s' => \$pidfile,
) or Usage "Invalid parameter";

Usage 'Extraneous options: ' . join ' ', @ARGV
  if @ARGV;

EnterDaemonMode $logfile, $logfile, $pidfile
  if $daemon;

display "$FindBin::Script V$VERSION started at " . localtime;

$clearadm  = Clearadm->new;
$clearexec = Clearexec->new;

$clearadm->SetNotify;

while () {
  # First check in with all systems
  SystemsCheckin;
  
  my ($sleep, @workItems) = $clearadm->GetWork;
  
  foreach (@workItems) {
    my %scheduledTask = %{$_};
    
    $scheduledTask{system} ||= 'All systems';
    
    if ($scheduledTask{system} =~ /all systems/i) {
      foreach my $system ($clearadm->FindSystem) {
        $scheduledTask{system} = $$system{name};
        $sleep = ExecuteTask $sleep, %scheduledTask;
      } # foreach
    } else {
      $sleep = ExecuteTask $sleep, %scheduledTask;
    } # if
  } # foreach  
  
  if ($sleep > 0) {
    verbose "Sleeping for $sleep seconds";
    sleep $sleep;
  } # if  
} # foreach

=pod

=head1 CONFIGURATION AND ENVIRONMENT

DEBUG: If set then $debug is set to this level.

VERBOSE: If set then $verbose is set to this level.

TRACE: If set then $trace is set to this level.

=head1 DEPENDENCIES

=head2 Perl Modules

L<FindBin>

L<Getopt::Long|Getopt::Long>

=head2 ClearSCM Perl Modules

=begin man 

 Clearadm
 Clearexec
 DateUtils
 Display
 TimeUtils
 Utils

=end man

=begin html

<blockquote>
<a href="http://clearscm.com/php/scm_man.php?file=clearadm/lib/Clearadm.pm">Clearadm</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=clearadm/lib/Clearexec.pm">Clearexec</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=lib/DateUtils.pm">DateUtils</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=lib/Display.pm">Display</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=lib/TimeUtils.pm">TimeUtils</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=lib/Utils.pm">Utils</a><br>
</blockquote>

=end html

=head1 BUGS AND LIMITATIONS

There are no known bugs in this script

Please report problems to Andrew DeFaria <Andrew@ClearSCM.com>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010, ClearSCM, Inc. All rights reserved.

=cut
