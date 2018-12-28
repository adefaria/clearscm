#!/usr/local/bin/perl

=pod

=head1 NAME $RCSfile: viewager.cgi,v $

View Aging

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision

$Revision: 1.11 $

=item Created:

Mon Oct 25 11:10:47 PDT 2008

=item Modified:

$Date: 2011/01/14 16:50:54 $

=back

=head1 SYNOPSIS

This script serves 4 distinct functions. One function is to find
old views and report them to their owners via email so that view cleanup can be
done. Another function just does a quick report stdout. Yet another function is
to present the list of views in a web page. Finally there is a function
(generate) which generates a cache file containing information about views. This
function is designed to be run by a scheduler such as cron. Note that the web
page function relies on and uses this cache file too.

=head1 DESCRIPTION

Most Clearcase administrators wrestle with trying to keep the number of views 
under control. Users often create views but seldom think to remove them. Views
grow old and forgotten.

Many approaches have been taken, usally emailing the users telling them to clean
up their views. This script, viewager.cgi, attempts to encapsulate the task of
gathering information about old views, informing users of which of their views
are old and presenting reports in the form of a web page showing all views
including old ones.

=head1 USAGE Email, Report and Generate modes

 Usage viewager.cgi: [-u|sage] [-region <region>] [-e|mail]
                     [-a|gethreshold <n>] [-n|brThreshold <n>]
                     [-ac|tion <act>] [-s|ort <field>]
                     [-v|erbose] [-d|ebug]

 Where:
   -u|sage:            Displays usage
   -region <region>:   Region to use when looking for views (Default
                       for generate action: all)
   -e|mail:            Send email to owners of old views
   -ag|eThreshold:     Number of days before a view is considered old
                       (Default: 180)
   -n|brThreshold <n>: Number of views to report. Can be used for say a
                       "top 10" old views. Useful with -action report
                       (Default: Report all views)
   -ac|tion <act>      Valid actions include 'generate' or 'report'.
                       Generate mode merely regenerates the cache file.
                       Report produces a quick report to stdout.
   -s|ort <field>:     Where <field> is one of <tag|ownerName|type|age>

   -ve|rbose:          Be verbose
   -d|ebug:            Output debug messages

=head1 USAGE Web Page mode

Parameters for the web page mode are provided by the CPAN module CGI and are
normally passed in as part of the URL. These parameters are specified as
name/value pairs:

  sortby=<tag|ownerName|type|age>
    Note: age will sort in a reverse numerical fashion

  user=<username>
    <username> can be a partial name (e.g. 'defaria')

=head1 DESCRIPTION

This script seek to handle the general issue of handling old views. In generate
mode this script goes through all views collecting data about all of the views
and creates a cache file. The reason for this is that this process is length
(At one client's site with ~2500 views takes about 1 hour). As such you'd
probably want to schedule the running of this for once a day.

Once the cache file is created other modes will read that file and report on it.
In report mode you can report to stdout. For example, the following will give
you a quick "top 10" oldest views:

 $ viewager.cgi -action report -n 10

You may wish to add the following to your conrtabe to generated the cachefile
nightly:

 0 0 * * * cd /<DocumentRoot>/viewager && /<path>/viewager.cgi -action=generate

=head1 User module

Since the method for translating a user's userid into other attributes like
the users fullname and email, we rely on a User.pm module to implement a User
object that takes a string identifying the user and return useful informaiton
about the user, specifically the fullname and email address.

=cut

use strict;
use warnings;

use FindBin;
use Getopt::Long;
use CGI qw (:standard :cgi-lib *table start_Tr end_Tr);
use CGI::Carp 'fatalsToBrowser';
use File::stat;
use Time::localtime;

use lib "$FindBin::Bin/lib", "$FindBin::Bin/../lib";

use Clearadm;
use ClearadmWeb;
use Clearcase;
use Clearcase::View;
use Clearcase::Views;
use DateUtils;
use Display;
use Mail;
use Utils;
use User;

my $VERSION  = '$Revision: 1.11 $';
  ($VERSION) = ($VERSION =~ /\$Revision: (.*) /);

my %opts;
my $clearadm;

$opts{sortby}       ||= 'age';
$opts{ageThreshold}   = 180; # Default number of days a view must be older than

my $subtitle = 'View Aging Report';
my $email;

my $port       = CGI::server_port;
   $port       = ($port == 80) ? '' : ":$port";
my $scriptName = CGI::script_name;
   $scriptName =~ s/index.cgi//;
my $script     = 'http://'
               . $Clearadm::CLEAROPTS{CLEARADM_SERVER}
               . $port
               . $scriptName;

my %total;
my $nbrThreshold;       # Number of views threshold - think top 10

sub GenerateRegion ($) {
  my ($region) = @_;

  verbose "Processing region $region";
  $total{Regions}++;

  my $views = Clearcase::Views->new ($region);
  my @Views = $views->views;
  my @views;

  verbose scalar @Views . " views to process";

  my $i = 0;

  for my $name (@Views) {
    $total{Views}++;

    if (++$i % 100 == 0) {
      verbose_nolf $i;
    } elsif ($i % 25 == 0) {
      verbose_nolf '.';
    }# if

    my $view = Clearcase::View->new ($name, $region);
    
    my $gpath;

    if ($view->webview) {
      # TODO: There doesn't appear to be a good way to get the gpath for a
      # webview since it's set to <nogpath>! Here we try to compose one using
      # $view->host and $view->access_path but this is decidedly Windows centric
      # and thus not portable. This needs to be fixed!
      $gpath = '\\\\' . $view->host . '\\' . $view->access_path;

      # Change any ":" to "$". This is to change things like D:\path -> D$\path.
      # This assumes we have permissions to access through the administrative
      # <drive>$ mounts.
      $gpath =~ s/:/\$/; 
    } else {
      $gpath = $view->gpath;
    } # if

    # Note if the view server is unreachable (e.g. user puts view on laptop and
    # the laptop is powered off), then these fields will be undef. Change them
    # to Unknown. (Should Clearcase::View.pm do this instead?).
    my $type   = $view->type;
       $type ||= 'Unknown';

    my $user;

    my $ownerid = $view->owner;

    if ($ownerid =~ /^\w+(\\|\/)(\w+)/) {
      # TODO: Handle user identification better
      #$user = User->new ($ownerid);

      $ownerid       = $2;
      $user->{name}  = $2;
      $user->{email} = "$2\@gddsi.com";
    } else {
      $ownerid       = 'Unknown';
      $user->{name}  = 'Unknown';
      $user->{email} = 'unknown@gddsi.com';
    } # if

    my $age       = 0;
    my $ageSuffix = '';

    my $modified_date = $view->modified_date;
    
    if ($modified_date) {
      $modified_date = substr $modified_date, 0, 16;
      $modified_date =~ s/T/\@/;

      # Compute age
      $age       = Age ($modified_date);
      $ageSuffix = $age != 1 ? 'days' : 'day';
    } # if

    my %oldView = $clearadm->GetView($view->tag, $view->region);

    my ($err, $msg);

    my %viewRec = (
      system    => $view->shost,
      region    => $view->region,
      tag       => $view->tag,
      owner     => $ownerid,
      ownerName => $user->{name},
      email     => $user->{email},
      type      => $type,
      gpath     => $gpath,
      age       => $age,
      ageSuffix => $ageSuffix,
    );

    # Some views have not yet been modified
    $viewRec{modified} = $modified_date if $modified_date;

    if (%oldView) {
      ($err, $msg) = $clearadm->UpdateView(%viewRec);

      error "Unable to update view $name in Clearadm\n$msg", $err if $err;
    } else {
      ($err, $msg) = $clearadm->AddView (%viewRec);

      error "Unable to add view $name to Clearadm\n$msg", $err if $err;
    } # if
  } # for

  verbose "\nProcessed region $region";
  
  return;
} # GenerateRegion

sub Generate ($) {
  my ($region) = @_;

  if ($region =~ /all/i) {
    for ($Clearcase::CC->regions) {
      GenerateRegion $_;
    } # for
  } else {
    GenerateRegion $region;
  } # if
  
  return;
} # Generate

sub Report (@) {
  my (@views) = @_;

  $total{'Views processed'} = @views;

  my @sortedViews;

  if ($opts{sortby} eq 'age') {
    # Sort by age numerically decending
    @sortedViews = sort { $$b{$opts{sortby}} <=> $$a{$opts{sortby}} } @views;
  } else {
    @sortedViews = sort { $$a{$opts{sortby}} cmp $$b{$opts{sortby}} } @views;
  } # if

  $total{Reported} = 0;

  for (@sortedViews) {
    my %view = %{$_};

    last
      if ($nbrThreshold and $total{Reported} + 1 > $nbrThreshold) or
         ($view{age} < $opts{ageThreshold});

    $total{Reported}++;

    if ($view{type}) {
      if ($view{type} eq 'dynamic') {
        $total{Dynamic}++;
      } elsif ($view{type} eq 'snapshot') {
        $total{Snapshot}++;
      } elsif ($view{type} eq 'webview') {
        $total{Webview}++
      } else {
        $total{$view{type}}++;
      } # if
    } else {
      $total{Unknown}++;
    } # if

format STDOUT_TOP =
            View Name                         Owner           View Type   Last Modified      Age
------------------------------------- ---------------------- ----------- ---------------- -----------
.
format STDOUT =
@<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<< @<<<<<<<<<<<<<<< @>>>> @<<<<
$view{tag},$view{owner},$view{type},$view{modified},$view{age},$view{ageSuffix}
.

    write;
  } # for
  
  return;
} # Report

sub FormatTable ($@) {
  my ($style, @views) = @_;
  
  my $table;

  my $nbrViews = @views;
  
  my $legend =
    font ({-class => 'label'}, 'View type: ') .
    font ({-class => 'dynamic'}, 'Dyanmic') .
    ' ' .
    font ({-class => 'snapshot'}, 'Snapshot') .
    ' ' .
    font ({-class => 'web'}, 'Web') .
    ' ' .
    font ({-class => 'unknown'}, 'Unknown');

  my $caption;

  my $regionDropdown = start_form (
    -action => $script,
  );

  $regionDropdown .= font {-class => 'captionLabel'}, 'Region: ';
  $regionDropdown .= popup_menu (
    -name     => 'region',
    -values   => [$Clearcase::CC->regions],
    -default  => $Clearcase::CC->region,
    -onchange => 'submit();',
  );

  $regionDropdown .= end_form;

  $caption .= start_table {
    class        => 'caption',
    cellspacing  => 1,
    width        => '100%',
  };

  $caption   .= start_Tr;
    $caption .= td {
       -align => 'left',
       -width => '30%',
    }, font ({-class => 'label'}, 'Registry: '),
       setField($Clearcase::CC->registry_host), '<br>',
       font ({-class => 'label'}, 'Views: '),
       $nbrViews;
    $caption .= td {
      -align => 'center',
      -width => '40%',
    }, $legend;
    $caption .= td {
      -align => 'right',
      -width => '30%',
    }, $regionDropdown;
  $caption .= end_Tr; 

  $caption .= end_table;

  $table .= start_table {
    cellspacing => 1,
    width       => '75%',
  };

  $table   .= caption $caption;
  $table   .= start_Tr {-class => 'heading'};
    $table .= th '#';

    # Set defaults if not set already
    $opts{sortby}  ||= 'age';
    $opts{reverse} ||= 0;
    
    my $parms  = $opts{user}         ? "&user=$opts{user}" : '';
       $parms .= $opts{reverse} == 1 ? '&reverse=0'        : '&reverse=1'; 

    if ($style eq 'full') {
      my $tagLabel   = 'Tag ';
      my $ownerLabel = 'Owner ';
      my $typeLabel  = 'Type ';
      my $ageLabel   = 'Age ';
      
      if ($opts{sortby} eq 'tag') {
        $tagLabel .= $opts{reverse} == 1 
                   ? img {src => 'up.png',   border => 0} 
                   : img {src => 'down.png', border => 0}; 
      } elsif ($opts{sortby} eq 'ownerName') {
        $ownerLabel .= $opts{reverse} == 1 
                     ? img {src => 'up.png',   border => 0} 
                     : img {src => 'down.png', border => 0}; 
      } elsif ($opts{sortby} eq 'type') {
        $typeLabel .= $opts{reverse} == 1 
                    ? img {src => 'up.png',   border => 0} 
                    : img {src => 'down.png', border => 0}; 
      } elsif ($opts{sortby} eq 'age') {
        $ageLabel .= $opts{reverse} == 1 
                   ? img {src => 'down.png', border => 0} 
                   : img {src => 'up.png',   border => 0}; 
      } # if
      
      $table .= th a {href => "$script?region=$opts{region}&sortby=tag$parms"},
        $tagLabel;
      $table .= th a {href => "$script?region=$opts{region}&sortby=ownerName$parms"},
        $ownerLabel;
      $table .= th a {href => "$script?region=$opts{region}&sortby=type$parms"},
        $typeLabel;
      $table .= th a {href => "$script?region=$opts{region}&sortby=age$parms"},
        $ageLabel;
    } else {
      $table .= th 'Tag';
      $table .= th 'Owner';
      $table .= th 'Type';
      $table .= th 'Age';
    } # if
  $table .= end_Tr;

  if ($opts{sortby} eq 'age') {
    # Sort by age numerically decending
    @views = $opts{reverse} == 1
           ? sort { $$a{$opts{sortby}} <=> $$b{$opts{sortby}} } @views
           : sort { $$b{$opts{sortby}} <=> $$a{$opts{sortby}} } @views;
  } else {
    @views = $opts{reverse} == 1
           ? sort { $$b{$opts{sortby}} cmp $$a{$opts{sortby}} } @views
           : sort { $$a{$opts{sortby}} cmp $$b{$opts{sortby}} } @views;
  } # if

  my $i;

  for (@views) {
    my %view = %{$_};

    next if $view{region} ne $opts{region};

    my $owner = $view{owner};

    if ($view{owner} =~ /\S+(\\|\/)(\S+)/) {
      $owner = $2;
    } # if

    $owner = $view{ownerName} ? $view{ownerName} : 'Unknown';

    next if $opts{user} and $owner ne $opts{user};

    my $rowClass= $view{age} > $opts{ageThreshold} ? 'oldview' : 'view';

    $table   .= start_Tr {
      class => $rowClass
    };
      $table .= td {
        class => 'center',
      }, ++$i;
      $table .= td {
        align => 'left', 
      }, a {
        href => "viewdetails.cgi?tag=$view{tag}&region=$opts{region}"
      }, $view{tag};
      $table .= td {
        align => 'left',
      }, a { 
        href => "$script?region=$opts{region}&user=$owner"
      }, $owner;
      $table .= td {
        class => 'center'
      }, font {
        class => $view{type}
      }, $view{type};
      $table .= td {
        class => 'right'
      }, font ({
        class => $view{type}
      }, $view{age}, ' ', $view{ageSuffix});
    $table .= end_Tr;
  } # for

  $table .= end_table;

  return $table
} # FormatTable

# TODO: Add an option to remove views older than a certain date

sub EmailUser ($@) {
  my ($emailTo, @oldViews) = @_;

  @oldViews = sort { $$b{age} <=> $$a{age} } @oldViews;

  my $msg  = '<style>' . join ("\n", ReadFile 'viewager.css') . '</style>';
     $msg .= <<"END";
<h1 align="center">You have old Clearcase Views</h1>

<p>Won't you take a moment to review this message and clean up any views you no
longer need?</p>

<p>The following views are owned by you and have not been modified in $opts{ageThreshold}
days:</p>
END

  $msg .= FormatTable 'partial', @oldViews;
  $msg .= <<"END";

<h3>How to remove views you no longer need</h3>

<p>There are several ways to remove Clearcase views, depending on the view
type and the tools you are using.</p>

<blockquote>
  <p><b>Dynamic Views</b>: If the view is a dynamic view you can use Clearcase
  Explorer to remove the view. Find the view in your Clearcase Explorer. If
  it's not there then add it as a standard view shortcut. Then right click on
  the view shortcut and select <b>Remove View</b> (not <b>Remove View
  Shortcut</b>).</p>

  <p><b>Snapshot Views</b>: A snapshot view is a view who's source storage can
  be located locally. You can remove a snapshot view in a similar manner as a
  dynamic view, by adding it to Clearcase Explorer if not already present. By
  doing so you need to tell Clearcase Explorer where the snapshot view storage
  is located.</p>

  <p><b>Webviews</b>: Webviews are like snapshot views but stored on the web
  server. If you are using CCRC or the CCRC plugin to Eclipse you would select
  the view and then do <b>Environment: Remove Clearcase View</b>.</p>
</blockquote>

<p>If you have any troubles removing your old views then submit a case and we
will be happy to assist you.</p>

<h3>But I need for my view to stay around even if it hasn't been modified</h3>

<p>If you have a long lasting view who does not get modified but needs to
remain, contact us and we can arrange for it to be removed from consideration
which will stop it from being reported as old.</p>

<p>Thanks.</p>
-- <br>
Your friendly Clearcase Administrator
END
 
  mail (
    to          => $emailTo,
#    to          => 'Andrew@DeFaria.com',
    mode        => 'html',
    subject     => 'Old views',
    data        => $msg,
  );
  
  return
} # EmailUser

sub EmailUsers (@) {
  my (@views) = @_;
  
  @views = sort { $$a{ownerName} cmp $$b{ownerName} } @views;

  my @userViews;
  my $currUser = $views [0]->{ownerName};

  for (@views) {
    my %view = %{$_};

    next
      unless $view{email};

    if ($currUser ne $view{ownerName}) {
      EmailUser $view{email}, @userViews
        if @userViews;

      $currUser = $view{ownerName};

      @userViews =();
    } else {
      if ($view{age} > $opts{ageThreshold}) {
        push @userViews, \%view
          if !-f "$view{gpath}/ageless";
      } # if
    } # if
  } # for

  display"Done";
  
  return;
} # EmailUsers

# Main
GetOptions (
  \%opts,
  'usage'        => sub { Usage },
  'verbose'      => sub { set_verbose },
  'debug'        => sub { set_debug },
  'region=s',
  'sortby=s',
  'action=s',
  'email',
  'ageThreshold=i',
  'nbrThreshold=i',
) or Usage "Invalid parameter";

# Get options from CGI
my %CGIOpts = Vars;

$opts{$_} = $CGIOpts{$_} for keys %CGIOpts;

local $| = 1;

# Announce ourselves
verbose "$FindBin::Script v$VERSION";

$clearadm = Clearadm->new;

if ($opts{action} and $opts{action} eq 'generate') {
  $opts{region} ||= 'all';

  Generate $opts{region};
  Stats \%total if $opts{verbose};
} else {
  if ($opts{region} and ($opts{region} eq 'Clearcase not installed')) {
    heading;
    displayError $opts{region};
    footing;
    exit 1; 
  } # if
  
  $opts{region} ||= $Clearcase::CC->region;

  my @views = $clearadm->FindView (
    'all',
    $opts{region},
    $opts{tag},
    $opts{user}
  );
  
  if ($opts{action} and $opts{action} eq 'report') {
    Report @views;
    Stats \%total;
  } elsif ($email) {
    EmailUsers @views;
  } else {
    heading $subtitle;

    display h1 {
      -class => 'center',
    }, $subtitle;

    display FormatTable 'full', @views;

    footing;
  } # if
} # if

=pod

=head1 CONFIGURATION AND ENVIRONMENT

DEBUG: If set then $debug is set to this level.

VERBOSE: If set then $verbose is set to this level.

TRACE: If set then $trace is set to this level.

=head1 DEPENDENCIES

=head2 Perl Modules

L<CGI>

L<CGI::Carp|CGI::Carp>

L<Data::Dumper|Data::Dumper>

L<File::stat|File::stat>

L<FindBin>

L<Getopt::Long|Getopt::Long>

L<Time::localtime|Time::localtime>

=head2 ClearSCM Perl Modules

=begin man 

 Clearadm
 ClearadmWeb
 Clearcase
 Clearcase::View
 Clearcase::Views
 DateUtils
 Display
 Mail
 Utils

=end man

=begin html

<blockquote>
<a href="http://clearscm.com/php/scm_man.php?file=clearadm/lib/Clearadm.pm">Clearadm</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=clearadm/lib/ClearadmWeb.pm">ClearadmWeb</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=lib/Clearcase.pm">Clearcase</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=lib/Clearcase/View.pm">Clearcase::View</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=lib/Clearcase/Views.pm">Clearcase::Views</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=lib/DateUtils.pm">DateUtils</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=lib/Display.pm">Display</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=lib/Mail.pm">Mail</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=lib/Utils.pm">Utils</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=clearadm/lib/User.pm">User</a><br>
</blockquote>

=end html

=head1 BUGS AND LIMITATIONS

There are no known bugs in this script

Please report problems to Andrew DeFaria <Andrew@ClearSCM.com>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010, ClearSCM, Inc. All rights reserved.

=cut
