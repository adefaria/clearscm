=pod

=head1 NAME $RCSfile: ClearadmWeb.pm,v $

Common routines for the web portion of Clearadm

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision

$Revision: 1.46 $

=item Created

Sat Dec 18 08:43:27 EST 2010

=item Modified

$Date: 2011/12/26 19:00:58 $

=back

=head1 SYNOPSIS

This module holds common web routines for the web portion of Clearadm.

=head1 DESCRIPTION

To be filled out.

=head1 ROUTINES

The following routines are exported:

=cut

package ClearadmWeb;

use warnings;
use strict;

use base 'Exporter';

use CGI qw (
  :standard
   start_a
   end_a
   start_div
   end_div
   start_li
   end_li
   start_table
   end_table
   start_td
   end_td
   start_Tr
   end_Tr
   start_ul
   end_ul
);

use Carp;
use File::Basename;

use FindBin;

use lib "$FindBin::Bin/../../lib";

use Clearadm;
use DateUtils;
use Display;
use Utils;

my $clearadm = Clearadm->new;

our $APPNAME= 'Clearadm';
our $VERSION  = '$Revision: 1.46 $';
   ($VERSION) = ($VERSION =~ /\$Revision: (.*) /);

our @EXPORT = qw (
  autoScale
  displayError
  displayAlert
  displayAlertlog
  displayFilesystem
  displayNotification
  displayRunlog
  displaySchedule
  displaySystem
  displayTask
  dbug
  dumpVars
  editAlert
  editFilesystem
  editNotification
  editSchedule
  editSystem
  editTask
  footing
  graphError
  heading
  makeAlertDropdown
  makeFilesystemDropdown
  makeIntervalDropdown
  makeNotificationDropdown
  makeSystemDropdown
  makeTimeDropdown
  makeTaskDropdown
  setField
  setFields
);

our @PREDEFINED_ALERTS = (
  'Email admin',
);

our @PREDEFINED_NOTIFICATIONS = (
  'Loadavg',
  'Filesystem',
  'Scrub',
  'Heartbeat',
  'System checkin',
  'Update systems',
);

our @PREDEFINED_TASKS = (
  'Loadavg',
  'Filesystem',
  'Scrub',
  'System checkin',
  'Update systems',
);

our @PREDEFINED_SCHEDULES = (
  'Loadavg',
  'Filesystem',
  'Scrub',
  'Update systems',
);

our @PREDEFINED_NOTMORETHAN = (
  'Once an hour',
  'Once a day',
  'Once a week',
  'Once a month',
);

our @PREDEFINED_MULTIPLIERS = (
  'Seconds',
  'Minutes',
  'Hours',
  'Days',
);

sub dbug ($) {
  my ($msg) = @_;

  display font ({-class => 'error'}, '<br>DEBUG: '). $msg;

  return;
} # dbug

sub displayError ($) {
  my ($msg) = @_;

  display font ({-class => 'error'}, 'Error: ') . $msg;

  return
} # displayError;

sub setField ($;$) {
  my ($field, $label) = @_;

  $label ||= 'Unknown';

  my $undef = font {-class => 'unknown'}, $label;

  return defined $field ? $field : $undef;
} # setField

sub setFields ($%) {
  my ($label, %rec) = @_;

  $rec{$_} = setField ($rec{$_}, $label)
    foreach keys %rec;

  return %rec;
} # setFields;

sub dumpVars (%) {
  my (%vars) = @_;

  foreach (keys %vars) {
    dbug "$_: $vars{$_}";
  } # foreach

  return;
} # dumpVars

sub graphError ($) {
  my ($msg) = @_;

  use GD;

  # Make the image fit the message. It seems that characters are ~ 7px wide.
  my $imageLength = length ($msg) * 7;

  my $errorImage = GD::Image->new ($imageLength, 20);

  # Allocate some colors
  my $white = $errorImage->colorAllocate (255, 255, 255);
  my $red   = $errorImage->colorAllocate (255, 0, 0);

  # Allow the text to shine through
  $errorImage->transparent($white);
  $errorImage->interlaced('true');

  # Now put out the message
  $errorImage->string (gdMediumBoldFont, 0, 0, $msg, $red);

  # And return it
  print "Content-type: image/png\n\n";
  print $errorImage->png;

  # Since we've "returned" the error in the form of an image, there's nothing
  # left for us to do so we can exit
  exit;
} # graphError

sub autoScale ($) {
  my ($amount) = @_;

  my $kbyte = 1024;
  my $meg   = (1024 * $kbyte);
  my $gig   = (1024 * $meg);

  my $size = $amount > $gig
           ? sprintf ('%.2f Gig',   $amount / $gig)
           : $amount > $meg
           ? sprintf ('%.2f Meg',   $amount / $meg)
           : sprintf ('%.2f Kbyte', $amount / $kbyte);

  return $size;
} # autoScale

sub _makeAlertlogSelection ($$) {
  my ($name, $default) = @_;

  $default ||= 'All';

  my %values;

  $values{All} = 'All';

  $values{$$_{$name}} = $$_{$name}
    foreach ($clearadm->FindAlertlog);

  my $dropdown = popup_menu {
    name    => $name,
    class   => 'dropdown',
    values  => [sort keys %values],
    default => $default,
  };

  return $dropdown;
} # _makeAlertlogSelection

sub _makeRunlogSelection ($$) {
  my ($name, $default) = @_;

  $default ||= 'All';

  my @values = sort $clearadm->GetUniqueList ('runlog', $name);

  unshift @values, 'All';

  my %values;

  foreach (@values) {
     unless ($_ eq '') {
       $values{$_} = $_;
     } else {
       $values{NULL} = '<NULL>';
     } #if
  } # foreach

  my $dropdown = popup_menu {
    name    => $name,
    class   => 'dropdown',
    values  => \@values,
    default => $default,
    labels  => \%values,
  };

  return $dropdown;
} # _makeRunlogSelection

sub _makeRunlogSelectionNumeric ($$) {
  my ($name, $default) = @_;

  $default ||= 'All';

  my @values = sort {$a <=> $b} $clearadm->GetUniqueList ('runlog', $name);

  unshift @values, 'All';

  my $dropdown = popup_menu {
    name    => $name,
    class   => 'dropdown',
    values  => [@values],
    default => $default,
  };

  return $dropdown;
} # _makeRunlogSelection

sub makeAlertDropdown (;$$) {
  my ($label, $default) = @_;

  $label ||= '';

  my @values;

  push @values, $$_{name}
    foreach ($clearadm->FindAlert);

  my $dropdown  = "$label ";
     $dropdown .= popup_menu {
    name    => 'alert',
    class   => 'dropdown',
    values  => [sort @values],
    default => $default,
  };

  return $dropdown;
} # makeAlertDropdown

sub makeMultiplierDropdown (;$$) {
  my ($label, $default) = @_;

  $label ||= '';

  my $dropdown  = "$label ";
     $dropdown .= popup_menu {
    name    => 'multiplier',
    class   => 'dropdown',
    values  => [sort @PREDEFINED_MULTIPLIERS],
    default => $default,
  };

  return $dropdown;
} # makeMultiplierDropdown

sub makeNoMoreThanDropdown (;$$) {
  my ($label, $default) = @_;

  $label ||= '';

  my $dropdown  = "$label ";
     $dropdown .= popup_menu {
    name    => 'nomorethan',
    class   => 'dropdown',
    values  => [sort @PREDEFINED_NOTMORETHAN],
    default => $default,
  };

  return $dropdown;
} # makeNoMorThanDropdown

sub makeFilesystemDropdown ($;$$$) {
  my ($system, $label, $default, $onchange) = @_;

  $label ||= '';

  my %filesystems;

  foreach ($clearadm->FindFilesystem ($system)) {
    my %filesystem = %{$_};

    my $value = "$filesystem{filesystem} ($filesystem{mount})";

    $filesystems{$filesystem{filesystem}} = $value;
  } # foreach

  my $dropdown .= "$label ";
     $dropdown .= popup_menu {
    name     => 'filesystem',
    class    => 'dropdown',
    values   => [sort keys %filesystems],
    labels   => \%filesystems,
    onChange => ($onchange) ? $onchange : '',
    default  => $default,
  };

  return span {id => 'filesystems'}, $dropdown;
} # makeFilesystemDropdown

sub makeIntervalDropdown (;$$$) {
  my ($label, $default, $onchange) = @_;

  $label ||= '';

  my @intervals = (
    'Minute',
    'Hour',
    'Day',
    'Month',
  );

  $default = ucfirst lc $default
    if $default;

  my $dropdown  = "$label ";
     $dropdown .= popup_menu {
    name     => 'scaling',
    id       => 'scalingFactor',
    class    => 'dropdown',
    values   => [@intervals],
    default  => $default,
    onchange => $onchange,
  };

   return span {id => 'scaling'}, $dropdown;
} # makeIntervalDropdown;

sub makeNotificationDropdown (;$$) {
  my ($label, $default) = @_;

  $label ||= '';

  my @values;

  push @values, $$_{name}
    foreach ($clearadm->FindNotification);

  my $dropdown  = "$label ";
     $dropdown .= popup_menu {
    name    => 'notification',
    class   => 'dropdown',
    values  => [sort @values],
    default => $default,
  };

  return $dropdown;
} # makeNotificationDropdown

sub makeRestartableDropdown (;$$) {
  my ($label, $default) = @_;

  $label ||= '';

  my @values = (
    'true',
    'false',
  );

  my $dropdown  = "$label ";
     $dropdown .= popup_menu {
    name    => 'restartable',
    class   => 'dropdown',
    values  => [@values],
    default => $default,
  };

  return $dropdown;
} # makeRestartableDropdown

sub makeSystemDropdown (;$$$%) {
  my ($label, $default, $onchange, %systems) = @_;

  $label ||= '';

  foreach ($clearadm->FindSystem) {
    my %system = %{$_};

    my $value  = $system{name};
       $value .= $system{alias} ? " ($system{alias})" : '';

    $systems{$system{name}} = $value;
  } # foreach

  my $systemDropdown .= "$label ";
     $systemDropdown .= popup_menu {
       name     => 'system',
       class    => 'dropdown',
       values   => [sort keys %systems],
       labels   => \%systems,
       onchange => ($onchange) ? $onchange : '',
       default  => $default,
    };

  return span {id => 'systems'}, $systemDropdown;
} # makeSystemDropdown

sub makeTaskDropdown (;$$) {
  my ($label, $default) = @_;

  $label ||= '';

  my @values;

  push @values, $$_{name}
    foreach ($clearadm->FindTask);

  my $taskDropdown  = "$label ";
     $taskDropdown .= popup_menu {
    name    => 'task',
    class   => 'dropdown',
    values  => [sort @values],
    default => $default,
  };

  return $taskDropdown;
} # makeTaskDropdown

sub makeTimeDropdown ($$$;$$$$$) {
  my (
    $table,
    $elementID,
    $system,
    $filesystem,
    $label,
    $default,
    $interval,
    $name,
  ) = @_;

  $label ||= '';

  my @times;

  $name ||= lc $label;

  push @times, 'Earliest';

  if ($table =~ /loadavg/i) {
    push @times, $$_{timestamp}
      foreach ($clearadm->GetLoadavg ($system, undef, undef, undef, $interval));
  } elsif ($table =~ /filesystem/i) {
    push @times, $$_{timestamp}
      foreach ($clearadm->GetFS ($system, $filesystem, undef, undef, undef, $interval));
  } # if

  push @times, 'Latest';

  unless ($default) {
    $default = $name eq 'start' ? 'Earliest' : 'Latest';
  } # unless

  my $timeDropdown = "$label ";
     $timeDropdown .= span {id => $elementID}, popup_menu {
    name    => $name,
    class   => 'dropdown',
    values  => [@times],
    default => $default,
  };

  return $timeDropdown;
} # makeTimeDropdown

sub heading (;$$) {
  my ($title, $type) = @_;

  if ($title) {
    $title = "$APPNAME: $title";
  } else {
    $title = $APPNAME;
  } # if

  display header;
  display start_html {
  	-title  => $title,
  	-author => 'Andrew DeFaria <Andrew@ClearSCM.com>',
  	-meta   => {
  	  keywords  => 'ClearSCM Clearadm',
      copyright => 'Copyright (c) ClearSCM, Inc. 2010, All rights reserved',
  	},
  	-script => [{
  	  -language => 'JavaScript',
  	  -src      => 'clearadm.js',
  	}],
  	-style   => ['clearadm.css', 'clearmenu.css'],
  }, $title;

  return if $type;

  my $ieTableWrapStart = '<!--[if gt IE 6]><!--></a><!--<![endif]--><!--'
                       . '[if lt IE 7]><table border="0" cellpadding="0" '
                       . 'cellspacing="0"><tr><td><![endif]-->';
  my $ieTableWrapEnd   = '<!--[if lte IE 6]></td></tr></table></a><![endif]-->';

  # Menubar
  display div {id=>'mastheadlogo'}, h1 {class => 'title'}, $APPNAME;
  display start_div {class => 'menu'};

  # Home
  display ul li a {href => '/clearadm'}, 'Home';

  my @allSystems = $clearadm->FindSystem;

  # Systems
  display start_ul;
    display start_li;
      display a {href => 'systems.cgi'}, "Systems$ieTableWrapStart";
        display start_ul;
          foreach (@allSystems) {
            my %system = %{$_};
            my $sysName  = ucfirst $system{name};
               $sysName .= " ($system{alias})"
                 if $system{alias};

            display li a {
              href => "systemdetails.cgi?system=$system{name}"
            }, ucfirst "&nbsp;$sysName";
          } # foreach
        display end_ul;
        display $ieTableWrapEnd;
        display end_li;
    display end_li;
  display end_ul;

  # Filesystems
  display start_ul;
    display start_li;
      display a {href => 'filesystems.cgi'}, "Filesystems$ieTableWrapStart";
        display start_ul;
          foreach (@allSystems) {
            my %system = %{$_};
            my $sysName  = ucfirst $system{name};
               $sysName .= " ($system{alias})"
                 if $system{alias};

            display li a {
              href => "filesystems.cgi?system=$system{name}"
            }, ucfirst "&nbsp;$sysName";
          } # foreach
        display end_ul;
        display $ieTableWrapEnd;
    display end_li;
  display end_ul;

  # Servers
  display start_ul;
    display start_li;
      display a {href => '#'}, "Servers$ieTableWrapStart";
      display start_ul {class => 'skinny'};
        display start_li;
          display start_a {href => 'vobs.cgi'};
          display "<span class='drop'><span>VOB</span>&raquo;</span>$ieTableWrapStart";
        display start_ul;
          display li a {href => "systemdetails.cgi?system=jupiter"}, '&nbsp;Jupiter (defaria.com)';
        display end_ul;
        display $ieTableWrapEnd;
        display end_li;

        display start_li;
        display start_a {href => 'views.cgi'};
        display "<span class='drop'><span>View</span>&raquo;</span>$ieTableWrapStart";
        display start_ul;
          display li a {href => "systemdetails.cgi?system=earth"}, '&nbsp;Earth';
          display li a {href => "systemdetails.cgi?system=mars"}, '&nbsp;Mars';
        display end_ul;
        display $ieTableWrapEnd;
      display end_ul;
      display $ieTableWrapEnd;
    display end_li;
  display end_ul;

  # Vobs
  display start_ul;
    display start_li;
      display a {href => 'vobs.cgi'}, "VOBs$ieTableWrapStart";
      display start_ul;
        display li a {href => '#'}, '&nbsp;/vobs/clearscm';
        display li a {href => '#'}, '&nbsp;/vobs/clearadm';
        display li a {href => '#'}, '&nbsp;/vobs/test';
        display li a {href => '#'}, '&nbsp;/vobs/test2';
      display end_ul;
      display $ieTableWrapEnd;
    display end_li;
  display end_ul;

  # Views
  display start_ul;
    display start_li;
      display a {href => 'views.cgi'}, "Views$ieTableWrapStart";
      display start_ul;
        display li a {href => 'viewager.cgi'}, '&nbsp;View Ager';
        display li a {href => '#'}, '&nbsp;Releast View';
      display end_ul;
      display $ieTableWrapEnd;
    display end_li;
  display end_ul;

  # Configure
  display start_ul;
    display start_li;
      display a {href => '#'}, "Configure$ieTableWrapStart";
      display start_ul;
        display li a {href => 'alerts.cgi'},        '&nbsp;Alerts';
        display li a {href => 'notifications.cgi'}, '&nbsp;Notifications';
        display li a {href => 'schedule.cgi'},      '&nbsp;Schedule';
        display li a {href => 'tasks.cgi'},         '&nbsp;Tasks';
      display end_ul;
      display $ieTableWrapEnd;
    display end_li;
  display end_ul;

  # Logs
  display start_ul;
    display start_li;
      display a {href => '#'}, "Logs$ieTableWrapStart";
      display start_ul;
        display li a {href => 'alertlog.cgi'}, '&nbsp;Alert';
        display li a {href => 'runlog.cgi'},   '&nbsp;Run';
      display end_ul;
      display $ieTableWrapEnd;
    display end_li;
  display end_ul;

  # Help
  display start_ul;
    display start_li;
      display a {href => '#'}, "Help$ieTableWrapStart";
      display start_ul {class => 'rightmenu'};
        display li a {href => 'readme.cgi'}, "&nbsp;About: $APPNAME $VERSION";
      display end_ul;
      display $ieTableWrapEnd;
    display end_li;
  display end_ul;
  display end_div;

  display start_div {class => 'page'};

  return;
} # heading

sub displayAlert (;$) {
  my ($alert) = @_;

  display start_table {cellspacing => 1};

  display start_Tr;
    display th {class => 'labelCentered'}, 'Actions';
    display th {class => 'labelCentered'}, 'Name';
    display th {class => 'labelCentered'}, 'Type';
    display th {class => 'labelCentered'}, 'Who';
    display th {class => 'labelCentered'}, 'Category';
  display end_Tr;

  foreach ($clearadm->FindAlert ($alert)) {
    my %alert = %{$_};

    $alert{who} = setField $alert{who}, 'System Administrator';

    display start_Tr;
      my $areYouSure = "Are you sure you want to delete the $alert{name} alert?";

      my $actions = start_form {
        method => 'post',
        action => 'processalert.cgi',
      };

      $actions .= input {
        name   => 'name',
        type   => 'hidden',
        value  => $alert{name},
      };

      if (InArray $alert{name}, @PREDEFINED_ALERTS) {
        $actions .= input {
          name     => 'delete',
          disabled => 'true',
          type     => 'image',
          src      => 'delete.png',
          alt      => 'Delete',
          value    => 'Delete',
          title    => 'Cannot delete predefined alert',
        };
        $actions .= input {
          name     => 'edit',
          disabled => 'true',
          type     => 'image',
          src      => 'edit.png',
          alt      => 'Edit',
          value    => 'Edit',
          title    => 'Cannot edit predefined alert',
        };
      } else {
        $actions .= input {
          name    => 'delete',
          type    => 'image',
          src     => 'delete.png',
          alt     => 'Delete',
          value   => 'Delete',
          title   => 'Delete',
          onclick => "return AreYouSure ('$areYouSure');",
        };
        $actions .= input {
          name    => 'edit',
          type    => 'image',
          src     => 'edit.png',
          alt     => 'Edit',
          value   => 'Edit',
          title   => 'Edit',
        };
      } # if

      display end_form;

      my $who = $alert{who};

      if ($who =~ /^([a-zA-Z0-9._-]+)@([a-zA-Z0-9.-]+\.[a-zA-Z]{2,4})$/) {
        $who = a {href => "mailto:$1\@$2"}, $who;
      } # if

      display td {class => 'dataCentered'}, $actions;
      display td {class => 'data'},         $alert{name};
      display td {class => 'data'},         $alert{type};
      display td {class => 'data'},         $who;
      display td {class => 'data'},
        (InArray $alert{name}, @PREDEFINED_ALERTS) ? 'Predefined' : 'User Defined';
    display end_Tr;
  } # foreach

  display end_table;

  display p {class => 'center'}, a {
    href => 'processalert.cgi?action=Add',
  }, 'New alert ', img {
    src    => 'add.png',
    border => 0,
  };

  return;
} # DisplayAlerts

sub displayAlertlog (%) {
  my (%opts) = @_;

  my $optsChanged;

  unless (($opts{oldalert}        and $opts{alert}         and
           $opts{oldalert}        eq  $opts{alert})        and
          ($opts{oldsystem}       and $opts{system}        and
           $opts{oldsystem}       eq  $opts{system})       and
          ($opts{oldnotification} and $opts{notification}  and
           $opts{oldnotification} eq  $opts{notification})) {
    $optsChanged = 1;
  } # unless

  my $condition;

  unless ($opts{id}) {
    $condition  = "alert like '%";
    $condition .= $opts{alert} ? $opts{alert} : '';
    $condition .= "%'";
    $condition .= ' and ';
    $condition .= "system like '%";
    $condition .= $opts{system} ? $opts{system} : '';
    $condition .= "%'";
    $condition .= ' and ';
    $condition .= "notification like '%";
    $condition .= $opts{notification} ? $opts{notification} : '';
    $condition .= "%'";
  } # unless

  my $total = $clearadm->Count ('alertlog', $condition);

  if ($opts{'nextArrow.x'}) {
    $opts{start} = $opts{next};
  } elsif ($opts{'prevArrow.x'}) {
    $opts{start} = $opts{prev};
  } else {
    $opts{start} = 0;
  } # if

  my $next = $opts{start} + $opts{page} < $total
           ? $opts{start} + $opts{page}
           : $opts{start};
  my $prev = $opts{start} - $opts{page} >= 0
           ? $opts{start} - $opts{page}
           : $opts{start};

  my $opts  = $opts{start} + 1;
     $opts .= '-';
     $opts .= $opts{start} + $opts{page} < $total
            ? $opts{start} + $opts{page}
            : $total;
     $opts .= " of $total";

  display start_form {
    method => 'post',
    action => 'alertlog.cgi'
  };

  # Hidden fields to pass along
  display input {name  => 'prev', type  => 'hidden', value => $prev};
  display input {name  => 'next', type  => 'hidden', value => $next};

  display input {
    name  => 'oldalert',
    type  => 'hidden',
    value => $opts{alert},
  };
  display input {
    name  => 'oldsystem',
    type  => 'hidden',
    value => $opts{system},
  };
  display input {
    name  => 'oldnotification',
    type  => 'hidden',
    value => $opts{notification},
  };

  my $caption = start_table {
    class       => 'caption',
    cellspacing => 1,
    width       => '100%',
  };

  $caption .= start_Tr;

    unless ($opts{id}) {
      $caption .= td {align => 'left'}, input {
        name     => 'prevArrow',
        type     => 'image',
        src      => 'left.png',
        alt      => 'Previous',
        value    => 'prev',
      };
    } else {
      $caption .= td {align => 'left'}, img {
        src      => 'left.png',
        disabled => 'disabled',
      };
    } # unless

    $caption .= td {align => 'center'}, $opts;

    unless ($opts{id}) {
      $caption .= td {align => 'right'}, input {
        name     => 'nextArrow',
        type     => 'image',
        src      => 'right.png',
        alt      => 'Next',
        value    => 'next',
      };
    } else {
      $caption .= td {align => 'right'}, img {
        src      => 'right.png',
        disabled => 'disabled',
      };
    } # unless

  $caption .= end_Tr;

  $caption .= end_table;

  display start_table {cellspacing => 1, width => '98%'};

  display caption $caption;

  display start_Tr;
    display th {class => 'labelCentered'}, '#';
    display th {class => 'labelCentered'}, 'Delete';
    display th {class => 'labelCentered'}, 'Name';
    display th {class => 'labelCentered'}, 'System';
    display th {class => 'labelCentered'}, 'Notification';
    display th {class => 'labelCentered'}, 'Date/Time';
    display th {class => 'labelCentered'}, 'Runlog';
    display th {class => 'labelCentered'}, 'Message';
  display end_Tr;

  display start_Tr;
    display td {
      class   => 'filter',
      align   => 'right',
      colspan => 2,
    }, b 'Filter:';
    display td {
      class => 'filter'
    }, _makeAlertlogSelection ('alert', $opts{alert});
    display td {
      class => 'filter'
    }, _makeAlertlogSelection ('system', $opts{system});
    display td {
      class => 'filter'
    }, _makeAlertlogSelection ('notification', $opts{notification});
    display td {
      class => 'filter',
    }, input {
      type  => 'submit',
      value => 'Update',
    };
    display end_form;
    display td {
      class   => 'filter',
      align   => 'center',
      colspan => 2,
    # TODO: Would like to have Clear All Alerts be Clear Alerts and for it to
    # clear only the alerts that have been filtered.
    }, a {
        href => 'deletealertlog.cgi?alertlogid=all'
    }, input {
      type    => 'button',
      value   => 'Clear All Events',
      onclick => "return AreYouSure('Are you sure you want to delete all alerts?');",
    };
  display end_Tr;

  my $i = $opts{start};

  foreach ($clearadm->FindAlertlog (
    $opts{alert},
    $opts{system},
    $opts{notification},
    $opts{start},
    $opts{page},
    )) {
    my %alertlog = setFields 'N/A', %{$_};

    display start_Tr;
      my %system = $clearadm->GetSystem ($alertlog{system});

      display td {class => 'dataCentered'}, ++$i;
      display td {class => 'dataCentered'}, a {
        href => "deletealertlog.cgi?alertlogid=$alertlog{id}"
      }, img {
        src => 'delete.png',
        alt     => 'Delete',
        title   => 'Delete',
        border  => 0,
        onclick => "return AreYouSure ('Are you sure you wish to delete this alertlog entry?');",
      };
      display td {class => 'data'}, a {
        href => "alerts.cgi?alert=$alertlog{alert}"
      }, $alertlog{alert};
      display td {class => 'data'}, a {
        href => "systemdetails.cgi?system=$alertlog{system}"
      }, $alertlog{system};
      display td {class => 'data'}, a {
        href => "notifications.cgi?notification=$alertlog{notification}"
      }, $alertlog{notification};
      display td {class => 'data'},         $alertlog{timestamp};
      display td {class => 'dataCentered'}, a {
        href => "runlog.cgi?id=$alertlog{runlog}"
      }, $alertlog{runlog};
      display td {class => 'data'},         $alertlog{message};
    display end_Tr;
  } # foreach

  display end_form;

  display end_table;

  return;
} # displayAlertlog

sub displayFilesystem ($) {
  my ($systemName) = @_;

  display start_table {cellspacing => 1, width => '98%'};

  display start_Tr;
    display th {class => 'labelCentered'}, 'Action';
    display th {class => 'labelCentered'}, 'Name';
    display th {class => 'labelCentered'}, 'Alias';
    display th {class => 'labelCentered'}, 'Admin';
    display th {class => 'labelCentered'}, 'Filesystem';
    display th {class => 'labelCentered'}, 'Mount';
    display th {class => 'labelCentered'}, 'Type';
    display th {class => 'labelCentered'}, 'History';
    display th {class => 'labelCentered'}, 'Used';
    display th {class => 'labelCentered'}, 'Threshold';
    display th {class => 'labelCentered'}, 'Usage';
  display end_Tr;

  foreach ($clearadm->FindSystem ($systemName)) {
    my %system = %{$_};

    %system = setFields ('N/A', %system);

    my $admin = ($system{email} !~ 'N/A')
              ? a {-href => "mailto:$system{email}"}, $system{admin}
              : $system{admin};

    foreach ($clearadm->FindFilesystem ($system{name})) {
      my %filesystem = %{$_};

      my %fs = $clearadm->GetLatestFS ($system{name}, $filesystem{filesystem});

      my $size = autoScale $fs{size};
      my $used = autoScale $fs{used};
      my $free = autoScale $fs{free};

      # TODO: Note that this percentages does not agree with df output. I'm not
      # sure why.
      my $usedPct = $fs{size} == 0 ? 0
                  : sprintf ('%.0f',
                     (($fs{reserve} + $fs{used}) / $fs{size} * 100));

      my $alias = ($system{alias} !~ 'N/A')
                ? a {
                    href => "systemdetails.cgi?system=$system{name}"
                  }, $system{alias}
                : $system{alias};

      my $class         = $usedPct < $filesystem{threshold}
                        ? 'data'
                        : 'dataAlert';
      my $classRight    = $usedPct < $filesystem{threshold}
                        ? 'dataRight'
                        : 'dataRightAlert';
      my $classCentered = $usedPct < $filesystem{threshold}
                        ? 'dataCentered'
                        : 'dataCenteredAlert';
      my $classRightTop = $usedPct < $filesystem{threshold}
                        ? 'dataRightTop'
                        : 'dataRightAlertTop';

      display start_Tr;
        display start_td {class => 'dataCentered'};

        my $areYouSure = 'Are you sure you want to delete '
                       . "$system{name}:$filesystem{filesystem}?" . '\n'
                       . 'Doing so will remove all records related to this\n'
                       . 'filesystem and its history.';

        display start_form {
          method => 'post',
          action => "processfilesystem.cgi",
        };

        display input {
          type  => 'hidden',
          name  => 'system',
          value => $system{name},
        };
        display input {
          type  => 'hidden',
          name  => 'filesystem',
          value => $filesystem{filesystem},
        };

        display input {
          name    => 'delete',
          type    => 'image',
          src     => 'delete.png',
          alt     => 'Delete',
          value   => 'Delete',
          title   => 'Delete',
          onclick => "return AreYouSure ('$areYouSure');"
        };
        display input {
          name    => 'edit',
          type    => 'image',
          src     => 'edit.png',
          alt     => 'Edit',
          value   => 'Edit',
          title   => 'Edit',
        };

        if ($filesystem{notification}) {
          display a {
            href => "alertlog.cgi?system=$filesystem{system}"}, img {
            src    => 'alert.png',
            border => 0,
            alt    => 'Alert!',
            title  => 'This filesystem has alerts',
          };
        } # if

        display end_form;

        display end_td;
        display td {class => $class},
          a {-href => "systemdetails.cgi?system=$system{name}"}, $system{name};
        display td {class => $class}, $alias;
        display td {class => $class}, $admin;
        display td {class => $class}, $filesystem{filesystem};
        display td {class => $class}, $filesystem{mount};
        display td {class => $class}, $filesystem{fstype};
        display td {class => $classCentered}, $filesystem{filesystemHist};
        display td {class => $classRightTop}, "$used ($usedPct%)<br>",
          font {class => 'unknown'}, "$fs{timestamp}";
        display td {class => $classRightTop}, "$filesystem{threshold}%";
        display td {class => $class},
          a {href =>
            "plot.cgi?type=filesystem&system=$system{name}"
          . "&filesystem=$filesystem{filesystem}&scaling=Day&points=7"
          }, img {
            src    => "plotfs.cgi?system=$system{name}"
                    . "&filesystem=$filesystem{filesystem}&tiny=1",
            border => 0,
          };
      display end_Tr;
    } # foreach
  } # foreach

  display end_table;

  return;
} # displayFilesystem

sub displayNotification (;$) {
  my ($notification) = @_;

  display start_table {cellspacing => 1};

  display start_Tr;
    display th {class => 'labelCentered'}, 'Actions';
    display th {class => 'labelCentered'}, 'Name';
    display th {class => 'labelCentered'}, 'Alert';
    display th {class => 'labelCentered'}, 'Condition';
    display th {class => 'labelCentered'}, 'Not More Than';
    display th {class => 'labelCentered'}, 'Category';
  display end_Tr;

  foreach ($clearadm->FindNotification ($notification)) {
    my %notification= setFields 'N/A', %{$_};

    display start_Tr;
    my $areYouSure = "Are you sure you want to delete the $notification{name} "
                   . 'notification?';

    my $actions = start_form {
      method => 'post',
      action => 'processnotification.cgi',
    };

    $actions .= input {
      name   => 'name',
      type   => 'hidden',
      value  => $notification{name},
    };

    if (InArray $notification{name}, @PREDEFINED_NOTIFICATIONS) {
      $actions .= input {
        name     => 'delete',
        disabled => 'true',
        type     => 'image',
        src      => 'delete.png',
        alt      => 'Delete',
        value    => 'Delete',
        title    => 'Cannot delete predefined notification',
      };
      $actions .= input {
        name     => 'edit',
        disabled => 'true',
        type     => 'image',
        src      => 'edit.png',
        alt      => 'Edit',
        value    => 'Edit',
        title    => 'Cannot edit predefined notification',
      };
    } else {
      $actions .= input {
        name    => 'delete',
        type    => 'image',
        src     => 'delete.png',
        alt     => 'Delete',
        value   => 'Delete',
        title   => 'Delete',
        onclick => "return AreYouSure ('$areYouSure');",
      };
      $actions .= input {
        name    => 'edit',
        type    => 'image',
        src     => 'edit.png',
        alt     => 'Edit',
        value   => 'Edit',
        title   => 'Edit',
      };
    } # if

    display end_form;

    display td {class => 'dataCentered'}, $actions;
    display td {class => 'data'},         $notification{name};
    display td {class => 'data'},         a {
      href => "alerts.cgi?alert=$notification{alert}"
    }, $notification{alert};
    display td {class => 'data'},         $notification{cond};
    display td {class => 'data'},         $notification{nomorethan};
    display td {class => 'data'},
      (InArray $notification{name}, @PREDEFINED_NOTIFICATIONS)
      ? 'Predefined'
      : 'User Defined';

    display end_Tr;
  } # foreach

  display end_table;

  display p {class => 'center'}, a {
    href => 'processnotification.cgi?action=Add',
  }, 'New notification', img {
    src    => 'add.png',
    border => 0,
  };

  return;
} # displayNotification

sub displayRunlog (%) {
  my (%opts) = @_;

  my $optsChanged;

  unless (($opts{oldtask}   and $opts{task}    or
           $opts{oldtask}   eq  $opts{task})   and
          ($opts{oldsystem} and $opts{system}  or
           $opts{oldsystem} eq  $opts{system}) and
          ($opts{oldnot}    and $opts{not}     or
           $opts{oldnot}    eq  $opts{not})    and
          ($opts{oldstatus} and $opts{status}  or
           $opts{oldstatus} eq  $opts{status})) {
    $optsChanged = 1;
  } # unless

  my $condition;

  unless ($opts{id}) {
    $condition  = "task like '%";
    $condition .= $opts{task} ? $opts{task} : '';
    $condition .= "%'";

    if ($opts{system}) {
      if ($opts{system} eq '<NULL>') {
        $condition .= ' and system is null';
        undef $opts{system}
      } elsif ($opts{system} ne 'All') {
        $condition .= " and system like '%$opts{system}%'";;
      } # if
    } # if

    if (defined $opts{status}) {
      $condition .= ' and ';
      unless ($opts{not}) {
        $condition .= "status=$opts{status}";
      } else {
        $condition .= "status<>$opts{status}";
      } # unless
    } # if
  } # unless

  my $total = $clearadm->Count ('runlog', $condition);

  $opts{start} = $opts{'nextArrow.x'} ? $opts{next} : $opts{prev};
  $opts{start} ||= 0;
  $opts{start} = 0
    if $optsChanged;

  my $next = $opts{start} + $opts{page} < $total
           ? $opts{start} + $opts{page}
           : $opts{start};
  my $prev = $opts{start} - $opts{page} >= 0
           ? $opts{start} - $opts{page}
           : $opts{start};

  my $opts  = $opts{'nextArrow.x'} ? $opts{next} + 1 : $opts{prev} + 1;
     $opts .= '-';
     $opts .= $opts{start} + $opts{page} < $total
            ? $opts{start} + $opts{page}
            : $total;
     $opts .= " of $total";

  display start_form {
    method => 'post',
    action => 'runlog.cgi'
  };

  # Hidden fields to pass along
  display input {name => 'prev',      type => 'hidden', value => $prev};
  display input {name => 'next',      type => 'hidden', value => $next};
  display input {name => 'oldtask',   type => 'hidden', value => $opts{task}};
  display input {name => 'oldsystem', type => 'hidden', value => $opts{system}};
  display input {name => 'oldnot',    type => 'hidden', value => $opts{not}};
  display input {name => 'oldstatus', type => 'hidden', value => $opts{status}};

  my $caption = start_table {
    class       => 'caption',
    cellspacing => 1,
    width       => '100%',
  };

  $caption .= start_Tr;

  unless ($opts{id}) {
    $caption .= td {align => 'left'}, input {
      name     => 'prevArrow',
      type     => 'image',
      src      => 'left.png',
      alt      => 'Previous',
      value    => 'prev',
    };
  } else {
    $caption .= td {align => 'left'}, img {
      src      => 'left.png',
      disabled => 'disabled',
    };
  } # unless

  $caption .= td {align => 'center'}, $opts;

  unless ($opts{id}) {
    $caption .= td {align => 'right'}, input {
      name     => 'nextArrow',
      type     => 'image',
      src      => 'right.png',
      alt      => 'Next',
      value    => 'next',
    };
  } else {
    $caption .= td {align => 'right'}, img {
      src      => 'right.png',
      disabled => 'disabled',
    };
  } # unless

  $caption .= end_Tr;

  $caption .= end_table;

  display start_table {cellspacing => 1, width => '98%'};

  display caption $caption;

  display start_Tr;
    display th {class => 'labelCentered'}, '#';
    display th {class => 'labelCentered'}, 'ID';
    display th {class => 'labelCentered'}, 'Task';
    display th {class => 'labelCentered'}, 'System';
    display th {class => 'labelCentered'}, 'Started';
    display th {class => 'labelCentered'}, 'Ended';
    display th {class => 'labelCentered'}, 'Status';
    display th {class => 'labelCentered'}, 'Message';
  display end_Tr;

  display start_Tr;
    $opts{not} ||= 'false';

    display start_form {
      method => 'post',
      action => 'runlog.cgi'
    };
    display td {
      class   => 'filter',
      align   => 'right',
      colspan => 2,
    }, b 'Filter:';
    display td {
      class => 'filter'
    }, _makeRunlogSelection ('task', $opts{task});
    display td {
      class => 'filter'
    }, _makeRunlogSelection ('system', $opts{system});
    display td {class => 'filter'}, '&nbsp;';
    display td {
      class => 'filter',
      align => 'right',
    }, "Not: ", checkbox {
      name    => 'not',
      value   => 'true',
      checked => $opts{not} eq 'true' ? 1 : 0,
      label   => '',
    };
    display td {
      class => 'filter'
    }, _makeRunlogSelectionNumeric ('status', $opts{status});
    display td {
      class => 'filter',
    }, input {
      type  => 'submit',
      value => 'Update',
    };

    display end_form;
  display end_Tr;

  my $i = $opts{start};

  my $status;

  if (defined $opts{status}) {
    if ($opts{status} !~ /all/i) {
      $status = $opts{not} ne 'true' ? $opts{status} : "!$opts{status}";
    } # if
  } # if

  foreach ($clearadm->FindRunlog (
    $opts{task},
    $opts{system},
    $status,
    $opts{id},
    $opts{start},
    $opts{page},
    )) {
    my %runlog = setFields 'N/A', %{$_};

    my $class         = $runlog{status} == 0
                      ? 'data'
                      : 'dataAlert';
    my $classCentered = $runlog{status} == 0
                      ? 'dataCentered'
                      : 'dataAlertCentered';
    my $classRight    = $runlog{status} == 0
                      ? 'dataRight'
                      : 'dataAlertRight';

    display start_Tr;
      display td {class => 'dataCentered'}, ++$i;
      display td {class => 'dataCentered'}, $runlog{id};
      display td {class => 'data'},         a {
        href => "tasks.cgi?task=$runlog{task}"
      }, $runlog{task};
      display td {class => 'data'}, $runlog{system} eq 'Localhost'
        ? $runlog{system}
        : a {
        href => "systemdetails.cgi?system=$runlog{system}"
      }, $runlog{system};
      display td {class => 'dataCentered'}, $runlog{started};
      display td {class => 'dataCentered'}, $runlog{ended};
      display td {class => $classRight},    $runlog{status};

      my $message = $runlog{message};
         $message =~ s/\r\n/<br>/g;

      display td {class => $class, width => '50%'},         $message;
    display end_Tr;
  } # foreach

  display end_table;

  return;
} # displayRunlog

sub displaySchedule () {
  display start_table {cellspacing => 1};

  display start_Tr;
    display th {class => 'labelCentered'}, 'Actions';
    display th {class => 'labelCentered'}, 'Active';
    display th {class => 'labelCentered'}, 'Name';
    display th {class => 'labelCentered'}, 'Task';
    display th {class => 'labelCentered'}, 'Notification';
    display th {class => 'labelCentered'}, 'Frequency';
    display th {class => 'labelCentered'}, 'Category';
  display end_Tr;

  foreach ($clearadm->FindSchedule) {
    my %schedule = setFields 'N/A', %{$_};

    display start_Tr;
    my $areYouSure = "Are you sure you want to delete the $schedule{name} "
                   . "schedule?";

    my $actions = start_form {
      method => 'post',
      action => 'processschedule.cgi',
    };

    $actions .= input {
      name   => 'name',
      type   => 'hidden',
      value  => $schedule{name},
    };

    if (InArray $schedule{name}, @PREDEFINED_SCHEDULES) {
      $actions .= input {
        name     => 'delete',
        disabled => 'true',
        type     => 'image',
        src      => 'delete.png',
        alt      => 'Delete',
        value    => 'Delete',
        title    => 'Cannot delete predefined schedule',
      };
      $actions .= input {
        name     => 'edit',
        disabled => 'true',
        type     => 'image',
        src      => 'edit.png',
        alt      => 'Edit',
        value    => 'Edit',
        title    => 'Cannot edit predefined schedule',
      };
    } else {
      $actions .= input {
        name    => 'delete',
        type    => 'image',
        src     => 'delete.png',
        alt     => 'Delete',
        value   => 'Delete',
        title   => 'Delete',
        onclick => "return AreYouSure ('$areYouSure');",
      };
      $actions .= input {
        name    => 'edit',
        type    => 'image',
        src     => 'edit.png',
        alt     => 'Edit',
        value   => 'Edit',
        title   => 'Edit',
      };
    } # if

    display end_form;

    display td {class => 'dataCentered'}, $actions;
    display td {class => 'dataCentered'}, checkbox {
      disabled => 'disabled',
      checked  => $schedule{active} eq 'true' ? 1 : 0,
    };
    display td {class => 'data'},         $schedule{name};
    display td {class => 'data'},         a {
      href => "tasks.cgi?task=$schedule{task}"
    }, $schedule{task};
    display td {class => 'data'},         a {
      href => "notifications.cgi?notification=$schedule{notification}"
    }, $schedule{notification};
    display td {class => 'data'},         $schedule{frequency};
    display td {class => 'data'},
      (InArray $schedule{name}, @PREDEFINED_SCHEDULES)
        ? 'Predefined'
        : 'User Defined';

    display end_Tr;
  } # foreach

  display end_table;

  display p {class => 'center'}, a {
    href => 'processschedule.cgi?action=Add',
  }, 'New schedule', img {
    src    => 'add.png',
    border => 0,
  };

  return;
} # displaySchedule

sub displaySystem ($) {
  my ($systemName) = @_;

  my %system = $clearadm->GetSystem ($systemName);

  unless (%system) {
    displayError "Nothing known about system $systemName";
    return;
  } # unless

  my $lastheardfromClass = 'dataCentered';
  my $lastheardfromData  = $system{lastheardfrom};

  my %load = $clearadm->GetLatestLoadavg ($systemName);

  unless ($clearadm->SystemAlive (%system)) {
    $lastheardfromClass = 'dataCenteredAlert';
    $lastheardfromData  = a {
      href  => "alertlog.cgi?system=$system{name}",
      class => 'alert',
      title => "Have not heard from $system{name} for a while"
    }, $system{lastheardfrom};
    $system{notification} = 'Heartbeat';
  } # unless

  my $admin = ($system{email})
            ? a {-href => "mailto:$system{email}"}, $system{admin}
            : $system{admin};

  $system{alias}  = setField $system{alias},  'N/A';
  $system{region} = setField $system{region}, 'N/A';

  display start_table {cellspacing => 1};

  display start_Tr;
    my $areYouSure = 'Are you sure you want to delete this system?\n'
                   . "Doing so will remove all records related to $system{name}"
                   . '\nincluding filesystem records and history as well as '
                   . 'loadavg history.';

    my $actions = start_form {
      method => 'post',
      action => 'processsystem.cgi',
    };

    $actions .= input {
      name   => 'name',
      type   => 'hidden',
      value  => $system{name},
    };

    $actions .= input {
      name    => 'delete',
      type    => 'image',
      src     => 'delete.png',
      alt     => 'Delete',
      value   => 'Delete',
      title   => 'Delete',
      onclick => "return AreYouSure ('$areYouSure');",
    };
    $actions .= input {
      name    => 'edit',
      type    => 'image',
      src     => 'edit.png',
      alt     => 'Edit',
      value   => 'Edit',
      title   => 'Edit',
    };
    $actions .= checkbox {
      disabled => 'disabled',
      checked  => $system{active} eq 'true' ? 1 : 0,
    };

    if ($system{notification}) {
      $actions .= a {
        href => "alertlog.cgi?system=$system{name}"}, img {
        src    => 'alert.png',
        border => 0,
        alt    => 'Alert!',
        title  => 'This system has alerts',
      };
    } # if

    display th {class => 'label'},                      "$actions Name:";
    display end_form;
    display td {class => 'dataCentered', colspan => 2}, $system{name};
    display th {class => 'label'},                      'Alias:';
    display td {class => 'dataCentered'},               $system{alias};
    display th {class => 'label'},                      'Admin:';
    display td {class => 'dataCentered', colspan => 2}, $admin;
    display th {class => 'label', colspan => 2},        'Type:';
    display td {class => 'dataCentered'},               $system{type};
  display end_Tr;

  display start_Tr;
    display th {class => 'label'},               'OS Version:';
    display td {class => 'data', colspan => 10}, $system{os};
  display end_Tr;

  display start_Tr;
    display th {class => 'label'}, 'Last Contacted:';
    display td {
      class => $lastheardfromClass,
      colspan => 2
    }, "$lastheardfromData ",
      font {class => 'dim' }, "<br>Up: $load{uptime}";
    display th {class => 'label'},        'Port:';
    display td {class => 'dataCentered'}, $system{port};
    display th {class => 'label'},        'Threshold:';
    display td {class => 'dataCentered'}, $system{loadavgThreshold};
    display th {class => 'label'},        'History:';
    display td {class => 'dataCentered'}, $system{loadavgHist};
    display th {class => 'label'},        'Load Avg:';
    display td {class => 'data'},
      a {href =>
        "plot.cgi?type=loadavg&system=$system{name}&scaling=Hour&points=24"
        }, img {
          src    => "plotloadavg.cgi?system=$system{name}&tiny=1",
          border => 0,
      };

  my $description = $system{description};
  $description =~ s/\r\n/<br>/g;

  display start_Tr;
    display th {class => 'label'},               'Description:';
    display td {class => 'data', colSpan => 10}, $description;
  display end_Tr;

  display end_table;

  display p {class => 'center'}, a {
    href => 'processsystem.cgi?action=Add',
  }, 'New system', img {
    src    => 'add.png',
    border => 0,
  };

  display h1 {class => 'center'},
    'Filesystem Details: ' . ucfirst $system{name};

  display start_table {cellspacing => 1};

  display start_Tr;
    display th {class => 'labelCentered'}, 'Action';
    display th {class => 'labelCentered'}, 'Filesystem';
    display th {class => 'labelCentered'}, 'Type';
    display th {class => 'labelCentered'}, 'Mount';
    display th {class => 'labelCentered'}, 'Size';
    display th {class => 'labelCentered'}, 'Used';
    display th {class => 'labelCentered'}, 'Free';
    display th {class => 'labelCentered'}, 'Used %';
    display th {class => 'labelCentered'}, 'Threshold';
    display th {class => 'labelCentered'}, 'History';
    display th {class => 'labelCentered'}, 'Usage';
  display end_Tr;

  foreach ($clearadm->FindFilesystem ($system{name})) {
    my %filesystem = %{$_};

    my %fs = $clearadm->GetLatestFS (
      $filesystem{system},
      $filesystem{filesystem}
    );

    my $size = autoScale $fs{size};
    my $used = autoScale $fs{used};
    my $free = autoScale $fs{free};

    # TODO: Note that this percentages does not agree with df output. I'm not
    # sure why.
    my $usedPct = $fs{size} == 0 ? 0
                : sprintf ('%.0f',
                   (($fs{reserve} + $fs{used}) / $fs{size} * 100));

    my $class         = $usedPct < $filesystem{threshold}
                      ? 'data'
                      : 'dataAlert';
    my $classCentered = $class . 'Centered';
    my $classRight    = $class . 'Right';

    display start_Tr;
        display start_td {class => 'data'};

        my $areYouSure = 'Are you sure you want to delete '
                       . "$system{name}:$filesystem{filesystem}?" . '\n'
                       . 'Doing so will remove all records related to this\n'
                       . 'filesystem and its history.';

        display start_form {
          method => 'post',
          action => 'processfilesystem.cgi',
        };

        display input {
          type  => 'hidden',
          name  => 'system',
          value => $system{name},
        };
        display input {
          type  => 'hidden',
          name  => 'filesystem',
          value => $filesystem{filesystem},
        };

        display input {
          name    => 'delete',
          type    => 'image',
          src     => 'delete.png',
          alt     => 'Delete',
          value   => 'Delete',
          title   => 'Delete',
          onclick => "return AreYouSure ('$areYouSure');"
        };
        display input {
          name    => 'edit',
          type    => 'image',
          src     => 'edit.png',
          alt     => 'Edit',
          value   => 'Edit',
          title   => 'Edit',
        };

        if ($filesystem{notification}) {
          display a {
            href => "alertlog.cgi?system=$filesystem{system}"}, img {
            src    => 'alert.png',
            border => 0,
            alt    => 'Alert!',
            title  => 'This filesystem has alerts',
          };
        } # if

        display end_form;
      display td {class => $class},         $filesystem{filesystem};
      display td {class => $classCentered}, $filesystem{fstype};
      display td {class => $class},         $filesystem{mount};
      display td {class => $classRight},    $size;
      display td {class => $classRight},    $used;
      display td {class => $classRight},    $free;
      display td {class => $classRight},    "$usedPct%";
      display td {class => $classRight},    "$filesystem{threshold}%";
      display td {class => $classCentered}, $filesystem{filesystemHist};
      display td {class => $classCentered},
        a {href =>
          "plot.cgi?type=filesystem&system=$system{name}"
        . "&filesystem=$filesystem{filesystem}"
        . "&scaling=Day&points=7"
        }, img {
           src    => "plotfs.cgi?system=$system{name}&"
                   . "filesystem=$filesystem{filesystem}"
                   . '&tiny=1',
           border => 0,
        };
    display end_Tr;
  } # foreach

  display end_table;

  return;
} # displaySystem

sub displayTask (;$) {
  my ($task) = @_;

  display start_table {cellspacing => 1, width => '98%'};

  display start_Tr;
    display th {class => 'labelCentered'}, 'Actions';
    display th {class => 'labelCentered'}, 'Name';
    display th {class => 'labelCentered'}, 'System';
    display th {class => 'labelCentered'}, 'Description';
    display th {class => 'labelCentered'}, 'Command';
    display th {class => 'labelCentered'}, 'Restartable';
    display th {class => 'labelCentered'}, 'Category';
  display end_Tr;

  foreach ($clearadm->FindTask ($task)) {
    my %task = %{$_};

    $task{system} = 'All Systems'
      unless $task{system};

    display start_Tr;
      my $areYouSure = "Are you sure you want to delete the $task{name} task?";

      my $actions = start_form {
        method => 'post',
        action => 'processtask.cgi',
      };

      $actions .= input {
        name   => 'name',
        type   => 'hidden',
        value  => $task{name},
      };

      if (InArray $task{name}, @PREDEFINED_TASKS) {
        $actions .= input {
          name     => 'delete',
          disabled => 'true',
          type     => 'image',
          src      => 'delete.png',
          alt      => 'Delete',
          value    => 'Delete',
          title    => 'Cannot delete predefined task',
        };
        $actions .= input {
          name     => 'edit',
          disabled => 'true',
          type     => 'image',
          src      => 'edit.png',
          alt      => 'Edit',
          value    => 'Edit',
          title    => 'Cannot edit predefined task',
        };
      } else {
        $actions .= input {
          name    => 'delete',
          type    => 'image',
          src     => 'delete.png',
          alt     => 'Delete',
          value   => 'Delete',
          title   => 'Delete',
          onclick => "return AreYouSure ('$areYouSure');",
        };
        $actions .= input {
          name    => 'edit',
          type    => 'image',
          src     => 'edit.png',
          alt     => 'Edit',
          value   => 'Edit',
          title   => 'Edit',
        };
      } # if

      display end_form;

      display td {class => 'dataCentered'}, $actions;
      display td {class => 'data'},         $task{name};
      display td {class => 'data'},         $task{system};
      display td {class => 'data'},         $task{description};
      display td {class => 'data'},         $task{command};
      display td {class => 'dataCentered'}, $task{restartable};
      display td {class => 'data'},
        (InArray $task{name}, @PREDEFINED_TASKS) ? 'Predefined' : 'User Defined';
    display end_Tr;
  } # foreach

  display end_table;

  display p {class => 'center'}, a {
    href => 'processtask.cgi?action=Add',
  }, 'New task', img {
    src    => 'add.png',
    border => 0,
  };

  return;
} # DisplayAlerts

sub editAlert (;$) {
  my ($alert) = @_;

  display start_form (
    -method   => 'post',
    -action   => 'processalert.cgi',
    -onsubmit => 'return validateAlert (this);',
  );

  my %alert;

  if ($alert) {
    %alert = $clearadm->GetAlert ($alert);

    return
      unless %alert;

    display input {
      name  => 'oldname',
      type  => 'hidden',
      value => $alert,
    };
  } else {
    $alert= '';
  } # if

  display input {
    name  => 'action',
    type  => 'hidden',
    value => 'Post',
  };

  display start_table {cellspacing => 1};

  display start_Tr;
    display th {class => 'labelCentered'}, 'Name';
    display th {class => 'labelCentered'}, 'Type';
    display th {class => 'labelCentered'}, 'Who';
  display end_Tr;

  display start_Tr;
    display td {
      class => 'data',
    }, input {
      class     => 'inputfield',
      maxlength => 255,
      name      => 'name',
      size      => 20,
      type      => 'text',
      value     => $alert ? $alert{name} : '',
    };
    display td {
      class => 'dataCentered',
    }, popup_menu {
      name    => 'type',
      class   => 'dropdown',
      values  => [ 'email', 'page', 'im' ],
      default => $alert ? $alert{type} : 'email',
    };
    display td {
      class => 'data',
    }, input {
      class     => 'inputfield',
      maxlength => 255,
      name      => 'who',
      size      => 20,
      type      => 'text',
      value     => $alert ? $alert{who} : '',
    };
  display end_Tr;
  display end_table;

  display '<center>';
  display p submit ({value => $alert ? 'Update' : 'Add'}),  reset;
  display '</center>';

  display end_form;

  return;
} # editAlert

sub editFilesystem ($$) {
  my ($system, $filesystem) = @_;

  display start_form (
    -method => 'post',
    -action => 'processfilesystem.cgi',
  );

  display start_table {width => '800px', cellspacing => 1};

  display start_Tr;
    display th {class => 'labelCentered'}, 'Filesystem';
    display th {class => 'labelCentered'}, 'Type';
    display th {class => 'labelCentered'}, 'Mount';
    display th {class => 'labelCentered'}, 'Size';
    display th {class => 'labelCentered'}, 'Used';
    display th {class => 'labelCentered'}, 'Free';
    display th {class => 'labelCentered'}, 'Used %';
    display th {class => 'labelCentered'}, 'History';
    display th {class => 'labelCentered'}, 'Threshold';
  display end_Tr;

  my %filesystem = $clearadm->GetFilesystem ($system, $filesystem);
  my %fs         = $clearadm->GetLatestFS   ($system, $filesystem);

  display input {
    name  => 'action',
    type  => 'hidden',
    value => 'Post',
  };
  display input {
    name  => 'system',
    type  => 'hidden',
    value => $filesystem{system},
  };
  display input {
    name  => 'filesystem',
    type  => 'hidden',
    value => $filesystem{filesystem},
  } ;

  my $size = autoScale $fs{size};
  my $used = autoScale $fs{used};
  my $free = autoScale $fs{free};

  display start_Tr;
    display td {class => 'data'},         $filesystem{filesystem};
    display td {class => 'dataCentered'}, $filesystem{fstype};
    display td {class => 'data'},         $filesystem{mount};
    display td {class => 'dataRight'},    $size;
    display td {class => 'dataRight'},    $used;
    display td {class => 'dataRight'},    $free;
    # TODO: Note that this percentages does not agree with df output. I'm not
    # sure why.
    display td {class => 'dataCentered'},
      sprintf ('%.0f%%', (($fs{reserve} + $fs{used}) / $fs{size} * 100));

    my $historyDropdown = popup_menu {
      name    => 'filesystemHist',
      class   => 'dropdown',
      values  => [
        '1 month',
        '2 months',
        '3 months',
        '4 months',
        '5 months',
        '6 months',
        '7 months',
        '8 months',
        '9 months',
        '10 months',
        '11 months',
        '1 year',
      ],
      default => $system ? $filesystem{filesystemHist} : '6 months',
    };

    display td {
      class => 'dataRight',
    }, $historyDropdown;

    my $thresholdDropdown = popup_menu {
      name    => 'threshold',
      class   => 'dropdown',
      values  => [1 .. 100],
      default => $filesystem{threshold},
    };
    display td {class => 'dataCentered'}, $thresholdDropdown . '%';
  display end_Tr;

  display end_table;

  display '<center>';
  display p submit ({value => 'Update'}),  reset;
  display '</center>';

  display end_form;

  return;
} # editFilesytem

sub editNotification (;$) {
  my ($notification) = @_;

  display start_form (
    -method   => 'post',
    -action   => 'processnotification.cgi',
    -onsubmit => 'return validateNotification (this);',
  );

  my %notification;

  if ($notification) {
    %notification = $clearadm->GetNotification ($notification);

    return
      unless %notification;

    display input {
      name  => 'oldname',
      type  => 'hidden',
      value => $notification,
    };
  } else {
    $notification = '';
  } # if

  display input {
    name  => 'action',
    type  => 'hidden',
    value => 'Post',
  };

  display start_table {cellspacing => 1};

  display start_Tr;
    display th {class => 'labelCentered'}, 'Name';
    display th {class => 'labelCentered'}, 'Alert';
    display th {class => 'labelCentered'}, 'Condition';
    display th {class => 'labelCentered'}, 'Not More Than';
  display end_Tr;

  display start_Tr;
    display td {
      class => 'data',
    }, input {
      class     => 'inputfield',
      maxlength => 255,
      name      => 'name',
      size      => 20,
      type      => 'text',
      value     => $notification ? $notification{name} : '',
    };

    display td {
      class => 'dataCentered',
    }, makeAlertDropdown undef, $notification{alert}
       ? $notification{alert}
       : 'Email admin';

    display td {
      class => 'data',
    }, input {
      class     => 'inputfield',
      maxlength => 255,
      name      => 'cond',
      size      => 20,
      type      => 'text',
      value     => $notification ? $notification{cond} : '',
    };
    display td {
      class => 'dataCentered',
    }, makeNoMoreThanDropdown undef, $notification{nomorethan};

  display end_Tr;
  display end_table;

  display '<center>';
  display p submit ({value => $notification ? 'Update' : 'Add'}),  reset;
  display '</center>';

  display end_form;

  return;
} # editNotification

sub editSchedule (;$) {
  my ($schedule) = @_;

  display start_form (
    -method   => 'post',
    -action   => 'processschedule.cgi',
    -onsubmit => 'return validateSchedule (this);',
  );

  my %schedule;

  if ($schedule) {
    %schedule = $clearadm->GetSchedule ($schedule);

    return
      unless %schedule;

    display input {
      name  => 'oldname',
      type  => 'hidden',
      value => $schedule,
    };
  } else {
    $schedule = '';
  } # if

  display input {
    name  => 'action',
    type  => 'hidden',
    value => 'Post',
  };

  display start_table {cellspacing => 1};

  display start_Tr;
    display th {class => 'labelCentered'}, 'Active';
    display th {class => 'labelCentered'}, 'Name';
    display th {class => 'labelCentered'}, 'Task';
    display th {class => 'labelCentered'}, 'Notification';
    display th {class => 'labelCentered'}, 'Frequency';
  display end_Tr;

  display start_Tr;
    display td {
      class => 'dataCentered',
    }, checkbox {
      name    => 'active',
      value   => 'true',
      checked => $schedule{active} eq 'false' ? 0 : 1,
      label   => '',
    };
    display td {
      class => 'data',
    }, input {
      class     => 'inputfield',
      maxlength => 255,
      name      => 'name',
      size      => 20,
      type      => 'text',
      value     => $schedule ? $schedule{name} : '',
    };
    display td {
      class => 'dataCentered',
    }, makeTaskDropdown undef, $schedule{task};
    display td {
      class => 'dataCentered',
    }, makeNotificationDropdown undef, $schedule{notification};

    my $nbr        = 5;
    my $multiplier = 'minutes';

    if ($schedule{frequency} =~ /(\d+)\s(\S+)/ ) {
      $nbr        = $1;
      $multiplier = $2;

      $multiplier .= 's' if $nbr == 1;
    } # if

    display td {
      class => 'data',
    }, input {
      class     => 'inputfieldRight',
      maxlength => 3,
      name      => 'nbr',
      size      => 1,
      type      => 'text',
      value     => $nbr,
    },
      ' ',
      makeMultiplierDropdown undef, $multiplier;

  display end_Tr;
  display end_table;

  display '<center>';
  display p submit ({value => $schedule ? 'Update' : 'Add'}),  reset;
  display '</center>';

  display end_form;

  return;
} # editSchedule

sub editSystem (;$) {
  my ($system) = @_;

  display start_form (
    -method   => 'post',
    -action   => 'processsystem.cgi',
    -onsubmit => 'return validateSystem (this);',
  );

  my %system;

  if ($system) {
    %system = $clearadm->GetSystem ($system);

    return
      unless %system;

    display input {
      name  => 'name',
      type  => 'hidden',
      value => $system,
    };
  } else {
    $system = '';
  } # if

  display input {
    name  => 'action',
    type  => 'hidden',
    value => 'Post',
  };

  display start_table {cellspacing => 1};

  display start_Tr;
    display th {class => 'label'}, checkbox ({
      name    => 'active',
      value   => 'true',
      checked => $system{active} eq 'false' ? 0 : 1,
      label   => '',
    }) . ' Name: ';

    if ($system) {
      display td {class => 'data'},  $system{name};
    } else {
      display td {
        class => 'data',
      }, input {
        class     => 'inputfield',
        maxlength => 255,
        name      => 'name',
        size      => 20,
        type      => 'text',
      };
    } # if

    display th {class => 'label'}, 'Alias:';
    display td {
      class => 'data',
    }, input {
      class     => 'inputfield',
      maxlength => 255,
      name      => 'alias',
      size      => 20,
      type      => 'text',
      value     => $system ? $system{alias} : '',
    };

    display th {class => 'label'}, 'Port:';
    display td {
      class => 'dataRight',
    }, input {
      class     => 'inputfieldRight',
      maxlength => 6,
      name      => 'port',
      size      => 4,
      type      => 'text',
      value     => $system
                 ? $system{port}
                 : $Clearadm::CLEAROPTS{CLEARADM_PORT},
    };

    my $systemTypeDropdown = popup_menu {
      name    => 'type',
      class   => 'dropdown',
      values  => ['Unix', 'Linux', 'Windows'],
      default => $system ? $system{type} : 'Linux',
    };

    display th {class => 'label'}, 'Type:';
    display td {
      class   => 'dataRight',
    },  $systemTypeDropdown;
  display end_Tr;

  display start_Tr;
    display th {class => 'label'}, 'Admin:';
    display td {
      class => 'data',
    }, input {
      class     => 'inputfield',
      maxlength => 255,
      name      => 'admin',
      size      => 20,
      type      => 'text',
      value     => $system ? $system{admin} : '',
    };
    display th {class => 'label'}, 'Admin Email:';
    display td {
      class => 'data',
    }, input {
      class     => 'inputfield',
      maxlength => 255,
      name      => 'email',
      size      => 20,
      type      => 'text',
      value     => $system ? $system{email} : '',
    };

    display th {class => 'label'}, 'Threshold:';
    display td {
      class => 'dataRight',
    }, input {
      class     => 'inputfieldRight',
      maxlength => 5,
      name      => 'loadavgThreshold',
      size      => 3,
      type      => 'text',
      value     => $system
                 ? $system{loadavgThreshold}
                 : $Clearadm::CLEAROPTS{CLEARADM_LOADAVG_THRESHOLD},
    };

    my $historyDropdown = popup_menu {
      name    => 'loadavgHist',
      class   => 'dropdown',
      values  => [
        '1 month',
        '2 months',
        '3 months',
        '4 months',
        '5 months',
        '6 months',
        '7 months',
        '8 months',
        '9 months',
        '10 months',
        '11 months',
        '1 year',
      ],
      default => $system ? $system{loadavgHist} : '6 months',
    };

    display th {class => 'label'}, 'History:';
    display td {
      class => 'dataRight',
    }, $historyDropdown;

  my $description = $system ? $system{description} : '';
     $description =~ s/\r\n/<br>/g;

  display start_Tr;
    display th {class => 'label'}, 'Description:';
    display td {
      class   => 'data',
      colspan => 7,
    }, textarea {
      class   => 'inputfield',
      cols    => 103,
      name    => 'description',
      rows    => 3,
      value   => $description,
    };
  display end_Tr;
  display end_table;

  display '<center>';
  display p submit ({value => $system ? 'Update' : 'Add'}),  reset;
  display '</center>';

  display end_form;

  return;
} # editSystem

sub editTask (;$) {
  my ($task) = @_;

  display start_form (
    -method   => 'post',
    -action   => 'processtask.cgi',
    -onsubmit => 'return validateTask (this);',
  );

  my %task;

  if ($task) {
    %task = $clearadm->GetTask ($task);

    return
      unless %task;

    display input {
      name  => 'oldname',
      type  => 'hidden',
      value => $task,
    };
  } else {
    $task = '';
  } # if

  display input {
    name  => 'action',
    type  => 'hidden',
    value => 'Post',
  };

  display start_table {cellspacing => 1};

  display start_Tr;
    display th {class => 'labelCentered'}, 'Name';
    display th {class => 'labelCentered'}, 'System';
    display th {class => 'labelCentered'}, 'Description';
    display th {class => 'labelCentered'}, 'Command';
    display th {class => 'labelCentered'}, 'Restartable';
  display end_Tr;

  display start_Tr;
    display td {
      class => 'data',
    }, input {
      class     => 'inputfield',
      maxlength => 255,
      name      => 'name',
      size      => 15,
      type      => 'text',
      value     => $task ? $task{name} : '',
    };
    my $systemDropdown = makeSystemDropdown (
      undef,
      $task{system} ? $task{system} : 'All Systems',
      undef, (
        'All systems' => undef,
        'Localhost'   => 'Localhost',
      ),
    );

    display td {class => 'data'}, $systemDropdown;

    display td {
      class => 'data',
    }, input {
      class     => 'inputfield',
      maxlength => 255,
      name      => 'description',
      size      => 30,
      type      => 'text',
      value     => $task ? $task{description} : '',
    };

    display td {
      class => 'data',
    }, input {
      class     => 'inputfield',
      maxlength => 255,
      name      => 'command',
      size      => 40,
      type      => 'text',
      value     => $task ? $task{command} : '',
    };

    display td {
      class => 'dataCentered',
    }, makeRestartableDropdown undef, $task{restartable};

  display end_Tr;
  display end_table;

  display '<center>';
  display p submit ({value => $task ? 'Update' : 'Add'}),  reset;
  display '</center>';

  display end_form;

  return;
} # editTask

sub footing () {
  my $clearscm = a {-href => 'http://clearscm.com'}, 'ClearSCM, Inc.';

  # Figure out which script by using CLEARADM_BASE.
  my $script = basename (url {-absolute => 1});
     $script = 'index.cgi'
       if $script eq 'clearadm';

  my $scriptFullPath = "$Clearadm::CLEAROPTS{CLEARADM_BASE}/$script";

  my ($year, $mon, $mday, $hour, $min, $sec) =
    ymdhms ((stat ($scriptFullPath))[9]);

  my $dateModified = "$mon/$mday/$year @ $hour:$min";

  $script = a {
    -href => "http://clearscm.com/php/scm_man.php?file=clearadm/$script"
  }, $script;

  display end_div;

  display start_div {-class => 'copyright'};
    display "$script: Last modified: $dateModified";
    display br "Copyright &copy; $year, $clearscm - All rights reserved";
  display end_div;

  print end_html;

  return;
} # footing

1;

=pod

=head1 CONFIGURATION AND ENVIRONMENT

DEBUG: If set then $debug is set to this level.

VERBOSE: If set then $verbose is set to this level.

TRACE: If set then $trace is set to this level.

=head1 DEPENDENCIES

=head2 Perl Modules

L<Carp>

L<CGI>

L<File::Basename|File::Basename>

L<FindBin>

L<GD>

=head2 ClearSCM Perl Modules

=begin man

 Clearadm
 DateUtils
 Display
 Utils

=end man

=begin html

<blockquote>
<a href="http://clearscm.com/php/scm_man.php?file=lib/Clearadm.pm">Clearadm</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=lib/DateUtils.pm">DateUtils</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=lib/Display.pm">Display</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=lib/Utils.pm">Utils</a><br>
</blockquote>

=end html

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Andrew DeFaria <Andrew@ClearSCM.com>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010, ClearSCM, Inc. All rights reserved.

=cut
