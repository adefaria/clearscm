#!/usr/bin/perl
################################################################################
#
# File:         releasenotes.cgi,v
# Revision:     1.1.1.1
# Description:  Produce an HTML table of bugs for a release page
# Author:       Andrew@DeFaria.com
# Created:      Fri May 31 15:34:50  2002
# Modified:     2007/05/17 07:45:48
# Language:     Perl
#
# (c) Copyright 2007, ClearSCM, Inc., all rights reserved.
#
################################################################################
use strict;
use CGI qw/:standard *table/;
use Cwd;
use lib qw(//sonscentral/users/adefaria/www/cgi-bin);
use cqc;

#%cqc::fields;
#$cqc::command;

my $page = new CGI;

my $release = $page->param ("release");
my @intro_notes;
my @buglines;

# Colors
my $header_background = "#ffffcc";
my $header_foreground = "#000000";
my $data_background   = "#ffffff";
my $data_foreground   = "#000000";

sub Error;
sub Footing;

sub ReleaseForm {
  print
    start_form ({-action => "/Release/releasenotes.cgi",
                 -method => "post"}) . 
      h4 ("Look up other Release:",
          textfield ({-name  => "release",
                      -size  => 12,
                      -value => "Please specify"}),
          submit ({-value => "Display"})
           ) . end_form . "\n";
} # ReleaseForm

sub Heading {
  my $release = shift;

  if ($release) {
    print header     (-title   => "Release $release")          . "\n" .
          start_html (-title   => "Release $release",
                      -author  => "Andrew\@DeFaria.com",
                      -link    => "#0000ee",
                      -vlink   => "#cc33cc",
                      -alink   => "#ff0000",
                      -bgcolor => "#eeffff",
                      -text    => "#000000",
                      -script  => {-language => "JavaScript1.2",
                                   -src      => "/Javascript/Heading.js"}),
          p          ({-align => "right"},
                     a ({-href => "/Release/addbug"}, "Add a bug to a release") . "\n" . br
                     a ({-href => "file://///sons-clearcase/Views/official/Tools/bin/clearcase/triggers/data/rel_2.2.lst"}, "Official US 2.2 list") . "\n" . br
                     a ({-href => "file://///sons-cc/Views/official/Tools/bin/clearcase/triggers/data/china_2.2.lst"}, "Official Shanghai 2.2 list")) . "\n" .
          h1         ({-align=>"CENTER"}, "Release $release") . "\n" .
          h2         ("Introduction")                         . "\n";
  } else {
    print header     (-title  => "Release $release")          . "\n" .
          start_html (-title  => "Release $release",
                      -author => "Andrew\@DeFaria.com")                . "\n";
    Error "Release not specified!";
  } # if
} # Heading

sub Footing {
  ReleaseForm;
  print script ({-language => "JavaScript1.2",
                 -src      => "/JavaScript/Footing.js"}) . "\n";
  print end_html;
} # Footing

sub PrintIntroNotes {
  (scalar (@intro_notes) == 0) ? return : print ul (@intro_notes) . "\n";
} # PrintIntroNotes

sub LockedLabel {
  my $bugid = shift;

  # We need to set a view context. Use the official view
  my $cwd = cwd;

  my $vob_server = "sons-clearcase";
  my $view_path  = "Views";
  my $view_name  = "official";
  my $vob        = "salira";
  my $official_view = '\\\\'       .
                      $vob_server  .
                      '\\'         .
                      $view_path   .
                      '\\'         .
                      $view_name   .
                      '\\'         .
                      $vob;

  chdir $official_view or die "Unable to set view context";
  my $output = `cleartool lslock -short lbtype:$bugid`;
  chomp $output;
  chdir $cwd or die "Unable to return from view context\n";

  # lslock returns the label if it is locked, otherwise it returns
  # an empty string
  return $output;
} # LabelLocked

sub ParseBugFile {
  my $buglist = shift;
  my ($result, $owner, $description, $bugid, $state, $line);
  my $bugnbr = 0;
  my $locked;

  open BUGLIST, "$buglist" or Error "Unable to open buglist: $buglist";

  while ($line = <BUGLIST>) {
    next if $line =~ /^\#/;     # Skip comments
    chomp $line;
    if ($line =~ /^\*/) {
      ($result, $line) = split (/\* /, $line);
      push (@intro_notes, li ([$line]) . "\n");
    } else {
      ($bugid) = split (/\s+/, $line);
      $result = cqc::GetBugRecord ($bugid, %fields);
      ($result <= 0) ? $owner = "Unknown" : $owner = $fields {owner};
      if ($result < 0) {
        $description = "Unable to connect to server!";
      } elsif ($result > 0) {
        $description = "Bug ID not found in Clearquest!";
      } else {
        # Description's too large. Use headline instead.
        $description = $fields {headline};
      } # if

      if (LockedLabel ($bugid)) {
        $locked = img ({-src => "/Images/CheckMark.gif"});
      } else {
        $locked = "&nbsp;";
      } #if

      if ($fields {state} eq "Verified" or $fields {state} eq "Closed") {
        $state = $fields {state};
        $locked = img ({-src => "/Images/CheckMark.gif"});
      } else {
        $state = b (font ({-color => "Red"}, $fields {state}));
      } # if

      push (@buglines,
        td ({-width   => "25",
             -align   => "center",
             -bgcolor => $data_background},
            small ++$bugnbr) .
        td ({-bgcolor => $data_background},
            small (a ({-href => "/cgi-bin/bugdetails.cgi?bugid=$bugid"}, $bugid))) .
        td ({-bgcolor => $data_background},
            small $state) .
        td ({-align   => "center",
             -bgcolor => $data_background},
            small (a ({-href => "mailto:$owner\@salira.com"}, $owner))) .
        td ({-align   => "center",
             -valign  => "center",
             -bgcolor => $data_background},
            $locked) . 
        td ({-bgcolor => $data_background},
            small $description) . "\n");
    } # if
  } # while
} # ParseBugFile

sub PrintBugTable {
  if (scalar (@buglines) == 0) {
    print h3 ("No bugs found!");
  } else {
    my $bugs = (scalar (@buglines) > 1) ? " bugs" : " bug";
    print "<table cellpadding=0 cellspacing=1 border=0 width=95% align=center bgcolor=Black>\n";
    print caption (small (strong (scalar (@buglines) . $bugs . " in this release"))) . "\n";
    print "<tbody><tr><td valign=top>\n";
    print start_table({-align       => "center",
                       -border      => 1,
                       -cellspacing => 1,
                       -cellpadding => 2,
                       -width       => "100%"}) . "\n" .
      Tr ({-valign => "top", -bgcolor => $header_background}, [
        th ({-width => "25"}, 
             font ({-color => $header_foreground}, small ("#"))) .
        th (font ({-color => $header_foreground}, small ("Bug ID"))) .
        th (font ({-color => $header_foreground}, small ("State"))) .
        th (font ({-color => $header_foreground}, small ("Owner"))) .
        th (font ({-color => $header_foreground}, small ("Locked?"))) .
        th (font ({-color => $header_foreground}, small ("Description")))
        ]) . "\n" .  
      Tr({-valign=>"TOP"}, \@buglines) . "\n" .
      end_table . "\n" .
      end_table;
  } # if
} # PrintBugTable

sub Error {
  my $errmsg = shift;
  print h3 ({-style => "Color: red;",
             -align => "CENTER"}, "ERROR: " . $errmsg);
  Footing;
  exit 1;
} # Error

# Main
Heading $release;
if ($release) {
  ParseBugFile ($release . ".bugs");
  PrintIntroNotes (@intro_notes);
  PrintBugTable (@buglines);
  Footing;
} # if
