#################################################################################
#
# File:         $RCSfile: MAPSWeb.pm,v $
# Revision:	$Revision: 1.1 $
# Description:  Routines for generating portions of MAPSWeb
# Author:       Andrew@DeFaria.com
# Created:      Fri Nov 29 14:17:21  2002
# Modified:     $Date: 2013/06/12 14:05:47 $
# Language:     perl
#
# (c) Copyright 2000-2006, Andrew@DeFaria.com, all rights reserved.
#
################################################################################
package MAPSWeb;

use strict;

use FindBin;

use lib $FindBin::Bin;

use MAPS;
use MAPSLog;
use MAPSUtil;

use CGI qw (:standard *table start_Tr end_Tr start_div end_div);
use vars qw (@ISA @EXPORT);

use Exporter;

@ISA = qw (Exporter);

@EXPORT = qw (
  Debug
  DisplayError
  Footing
  Heading
  NavigationBar
);

sub getquickstats {
  my $date = shift;

  my %dates = GetStats (1, $date);

  foreach (@MAPSLog::Types) {
    $dates{$date}{processed} += $dates{$date}{$_};
  } # foreach

  return %dates;
} # getquickstats

sub displayquickstats {
  # Quick stats are today only.
  my $today = Today2SQLDatetime;
  my $time  = substr $today, 11;
  my $date  = substr $today, 0, 10;
  my %dates = getquickstats $date;

  print start_div {-class => 'quickstats'};
  print h4 {-class	=> 'header',
	    -align	=> 'center'},
    'Today\'s Activity';
  print p {-align	=> 'center'},
    b ('as of ' . FormatTime ($time));
  print start_table {
    -align		=> 'center',
    -border		=> 0,
    -cellspacing	=> 0,
    -cellpadding	=> 2};
  print start_Tr {-align => 'right'};
  print
    td {-class	=> 'smalllabel',
	-align	=> 'right'},
      'Processed';
  print
    td {-class	=> 'smallnumber',
	-align	=> 'right'},
      $dates{$date}{'processed'};
  print
    td {-class	=> 'smallnumber',
	-align	=> 'right'},
      'n/a';
  print end_Tr;

  foreach (@MAPSLog::Types) {
    print start_Tr {-align => 'right'};

    my $value = $dates{$date}{$_};
    my $percent;
    if ($_ eq 'mailloop' || $_ eq 'registered') {
      $percent = 'n/a';
    } else {
      $percent = $dates{$date}{processed} == 0 ?
	0 : $dates{$date}{$_} / $dates{$date}{processed} * 100;
      $percent = sprintf '%5.1f%s', $percent, '%';
    } # if
    my $stat = $value == 0 ?
      0 : a {-href => "detail.cgi?type=$_;date=$date"}, $value;
    print
      td {-class	=> 'smalllabel'}, ucfirst ($_);
    print
      td {-class	=> 'smallnumber'}, $stat;
    print
      td {-class	=> 'smallnumber'}, $percent;
    print end_Tr;
  } # foreach
  print end_table;
  print end_div;
} # displayquickstats

sub Footing (;$) {
  my ($table_name) = @_;

  # General footing (copyright). Note we calculate the current year
  # so that the copyright automatically extends itself.
  my $year = substr ((scalar (localtime)), 20, 4);

  print start_div {-class => "copyright"};
  print "Copyright &copy; 2001-$year - All rights reserved";
  print br (
    a ({-href => 'http://defaria.com'},
      'Andrew DeFaria'),
    a ({-href => 'mailto:Andrew@DeFaria.com'},
      '&lt;Andrew@DeFaria.com&gt;'));
  print end_div;

  print end_div; # This div ends "content" which was started in Heading
  print "<script language='JavaScript1.2'>AdjustTableWidth (\"$table_name\");</script>"
    if $table_name;
  print end_html;
} # Footing

sub Debug ($) {
  my ($msg) = @_;

  print br, font ({ -class => 'error' }, 'DEBUG: '), $msg;
} # Debug

sub DisplayError ($) {
  my ($errmsg) = @_;

  print h3 ({-class => 'error',
             -align => 'center'}, 'ERROR: ' . $errmsg);

  Footing;

  exit 1;
} # DisplayError

# This subroutine puts out the header for web pages. It is called by
# various cgi scripts thus has a few parameters.
sub Heading ($$$$;$$@) {
  my ($action,		# One of getcookie, setcookie, unsetcookie
      $userid,		# User id (if setting a cookie)
      $title,		# Title string
      $h1,		# H1 header
      $h2,		# H2 header (optional)
      $table_name,	# Name of table in page, if any
      @scripts)	= @_;   # Array of JavaScript scripts to include

  my @java_scripts;
  my $cookie;

  # Since CheckAddress appears on all pages (well except for the login
  # page) include it by default along with MAPSUtils.js
  push @java_scripts, [
    {-language	=> 'JavaScript1.2',
     -src	=> '/maps/JavaScript/MAPSUtils.js'},
    {-language	=> 'JavaScript1.2',
     -src	=> '/maps/JavaScript/CheckAddress.js'}
  ];

  # Add on any additional JavaScripts that the caller wants. Note the
  # odd single element array of hashes but that's what CGI requires!
  # Build up scripts from array
  foreach (@scripts) {
    push @{$java_scripts[0]},
      {-language	=> 'JavaScript1.2',
       -src		=> "/maps/JavaScript/$_"}
  } # foreach

  # Since Heading is called from various scripts we sometimes need to
  # set a cookie, other times delete a cookie but most times return the
  # cookie.
  if ($action eq 'getcookie') {
    # Get userid from cookie
    $userid = cookie ('MAPSUser');
  } elsif ($action eq 'setcookie') {
    $cookie = cookie (
       -name	=> 'MAPSUser',
       -value	=> $userid,
       -expires	=> '+1y',
       -path	=> '/maps'
    );
  } elsif ($action eq 'unsetcookie') {
    $cookie = cookie (
       -name	=> 'MAPSUser',
       -value	=> '',
       -expires	=> '-1d',
       -path	=> '/maps'
    );
  } # if

  print
    header     (-title	=> "MAPS: $title",
		-cookie => $cookie);

  if (defined $table_name) {
    print
      start_html (-title	=> "MAPS: $title",
		  -author	=> 'Andrew\@DeFaria.com',
		  -style	=> {-src	=> '/maps/css/MAPSStyle.css'},
		  -onResize	=> "AdjustTableWidth (\"$table_name\");",
		  -head		=> [
		    Link ({-rel  => 'icon',
	   		   -href => '/maps/MAPS.png',
			   -type => 'image/png'}),
	    	    Link ({-rel  => 'shortcut icon',
			   -href => '/maps/favicon.ico'})
                  ],
		  -script	=> @java_scripts);
  } else {
    print
      start_html (-title	=> "MAPS: $title",
		  -author	=> 'Andrew\@DeFaria.com',
		  -style	=> {-src	=> '/maps/css/MAPSStyle.css'},
		  -head		=> [
		     Link ({-rel  => 'icon',
	   		    -href => '/maps/MAPS.png',
			    -type => 'image/png'}),
	    	     Link ({-rel  => 'shortcut icon',
			    -href => '/maps/favicon.ico'})],
		  -script	=> @java_scripts);
  } # if

  print start_div {class => 'heading'};
  print h2 {-align	=> 'center',
	    -class	=> 'header'},
    font ({-class	=> 'standout'}, 'MAPS'),
      $h1;

  if (defined $h2 && $h2 ne '') {
    print h3 {-align	=> 'center',
	      -class	=> 'header'},
      $h2;
  } # if
  print end_div;

  # Start body content
  print start_div {-class => 'content'};

  return $userid
} # Heading

sub NavigationBar {
  my $userid = shift;

  print start_div {-id => 'leftbar'};

  if (!defined $userid) {
    print div ({-class	=> 'username'}, 'Welcome to MAPS');
    print div ({-class	=> 'menu'},
      (a {-href	=> '/maps/doc/'},
        'What is MAPS?<br>'),
      (a {-href	=> '/maps/doc/SPAM.html'},
        'What is SPAM?<br>'),
      (a {-href	=> '/maps/doc/Requirements.html'},
        'Requirements<br>'),
      (a {-href	=> '/maps/SignupForm.html'},
        'Signup<br>'),
      (a {-href	=> '/maps/doc/Using.html'},
        'Using MAPS<br>'),
      (a {-href	=> '/maps/doc/'},
        'Help<br>'),
    );
  } else {
    print div ({-class	=> 'username'}, 'Welcome '. ucfirst $userid);
    print div ({-class	=> 'menu'},
      (a {-href	=> '/maps/'},
        'MAPS Home<br>'),
      (a {-href	=> '/maps/bin/stats.cgi'},
        'Statistics<br>'),
      (a {-href	=> '/maps/bin/editprofile.cgi'},
        'Edit Profile<br>'),
      (a {-href	=> '/maps/php/Reports.php'},
        'Reports<br>'),
      (a {-href	=> '/maps/php/list.php?type=white'},
        'White List<br>'),
      (a {-href	=> '/maps/php/list.php?type=black'},
        'Black List<br>'),
      (a {-href	=> '/maps/php/list.php?type=null'},
        'Null List<br>'),
      (a {-href	=> '/maps/doc/'},
        'Help<br>'),
      (a {-href	=> '/maps/adm/'},
        'MAPS Admin<br>'),
      (a {-href	=> '/maps/?logout=yes'},
        'Logout'),
    );
    print start_div {-class => 'search'};
    print start_form {-method	=> 'get',
  		      -action	=> '/maps/bin/search.cgi',
  		      -name	=> 'search'};
    print 'Search Sender/Subject',
      textfield {-class		=> 'searchfield',
		 -id		=> 'searchfield',
  	         -name		=> 'str',
  	         -size		=> 20,
  	         -maxlength	=> 255,
  	         -value		=> '',
  	         -onclick	=> "document.search.str.value = '';"};
    print end_form;
    print end_div;

    displayquickstats;

    print start_div {-class => 'search'};
    print start_form {-method	=> 'post',
  		      -action	=> 'javascript://',
  		      -name	=> 'address',
  		      -onsubmit	=> 'checkaddress(this);'};
    print 'Check Email Address',
      textfield {-class		=> 'searchfield',
		 -id		=> 'searchfield',
  	         -name		=> 'email',
  	         -size		=> 20,
  	         -maxlength	=> 255,
  	         -value		=> '',
   	         -onclick	=> "document.address.email.value = '';"};
    print end_form;
    print end_div;
  } # if

  print end_div;
} # NavigationBar

1;
