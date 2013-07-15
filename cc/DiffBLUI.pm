=head1 NAME

Diffbl.pm: Perl/Tk UI for diffbl.pl

=head1 USAGE

 use DiffBLUI.pm;

 CreateUI;

=head1 DESCRIPTION

This Perl module encapsulates the Perl/Tk UI for diffbl.pl.

=head1 AUTHOR

Andrew DeFaria <Andrew@ClearSCM.com>

=head1 COPYRIGHT

Copyright (c) 2010 Andrew DeFaria <Andrew@ClearSCM.com>, ClearSCM, Inc.
All rights reserved.

=cut

package DiffBLUI;

use strict;
use warnings;

use Cwd;
use POSIX;
use Tk;
use Tk::BrowseEntry;
use Tk::DialogBox;
use Tk::ROText;

use lib '../lib';

use Clearcase;
use Display;
use OSDep;

use CCDBService;

use base 'Exporter';

my $VERSION = '1.0';

our (
  %SELECTED,
  %LINES,
  $MODE,
  $INTEGRATIONACTIVITIES,
  $integrationActivitiesCheck
);

my ($msgWidget, $searchPattern);

our @EXPORT = qw (
  createUI
  displayLines
  Tkerror
  Tkmsg
);

# Globals
my $TITLE  = 'Compare Baselines: Use fields to select baselines then ';
   $TITLE .= 'select Compare';
   
my $CCDBService = CCDBService->new;

# Widgets
my (
  $main,
  $versionsMenu,
  $activitiesMenu,
  $pvobDropdown,
  $streamDropdown,
  $fromBaselineDropdown,
  $toBaselineDropdown,
  $compareButton,
  $output,
);

# Data
my (@pvobs, @streams, @fromBaselines, @toBaselines);

sub createButton ($$$) {
  my ($parent, $label, $action) = @_;

  $parent->Button (
    -text    => $label,
    -width   => length $label,
    -command => \$action
  )->pack (
    -side    => "left",
    -padx    => 5,
    -pady    => 5,
  );
  
  return;
} # createButton

sub createDropdown ($$$;$$) {
  my ($parent, $label, $variable, $action, $list) = @_;

  my $widget = $parent->BrowseEntry (
    -label     => "$label:",
    -font      => 'Arial 8 bold',
    -variable  => $variable,
    -width     => 175,
    -takefocus => 1,
  )->pack (
    -padx      => 5,
    -pady      => 2,
  );

  if ($action) {
    # Any of these cause the action to be invoked
    $widget->configure (-browsecmd    => \$action);
    $widget->bind      ('<FocusOut>'  => \$action);
    $widget->bind      ('<Return>'    => \$action);
  } # if

  $widget->configure (-listcmd => \$list)
    if $list;

  my $listBox = $widget->Subwidget ('slistbox');
  my $entry   = $widget->Subwidget ('entry'); 
  my $arrow   = $widget->Subwidget ('arrow');
  my $choices = $widget->Subwidget ('choices');
  
  # Turn off bolding on the entry
  $entry->configure (-font => 'Arial 8');

  # Allow both widgets to have highlighted parts
  $listBox->configure (-exportselection => 0);
  $entry->configure   (-exportselection => 0);

  # Take the arrow out of the focus business - Works on Unix! 
  # Bug on Windows! :-(
  $arrow->configure (-takefocus => 0);

  # This gets the mouse wheel working - Works on Unix!
  # Bug on Windows! :-(
  $choices->bind ('<Button-4>', sub {$choices->yviewScroll (1,'units')});
  $choices->bind ('<Button-5>', sub {$choices->yviewScroll (-1,'units')});
  $choices->bind ('<Button-4>', sub {$choices->yview (1,'units')});
  $choices->bind ('<Button-5>', sub {$choices->yview (-1,'units')});

  foreach (
    '<KeyPress>',
    '<Up>',
    '<Down>',
    '<Control-Key-p>',
    '<Control-Key-n>'
  ) {
    $entry->bind ($_, [\&handleKeypress, $listBox]);
  } # foreach 

  return $widget;
} # createDropdown

sub createList ($) {
  my ($parent) = @_;

  my $widget = $parent->Scrolled ('Listbox',
    -height     => 10,
    -width      => 100,
    -scrollbars => 'e',
  )->pack (
    -padx       => 5,
    -pady       => 5,
    -fill       => 'both',
    -expand     => 'yes',
    -anchor     => 'w',
  );

  # Make this list resizeable
  $parent->pack (
    -fill       => 'both',
    -expand     => 'yes',
  );

  # Bind actions
  $widget->bind ('<ButtonPress-3>', [ \&popupCCActions, Ev('@') ]);
  $widget->bind ('<Double-ButtonPress-1>', \&properties);
      
  # This gets the mouse wheel working
  $widget->bind ('<Button-4>', sub {$widget->yviewScroll (1,'units')});
  $widget->bind ('<Button-5>', sub {$widget->yviewScroll (-1,'units')});

  return $widget;
} # createList

sub setList ($@) {
  my ($list, @value) = @_;

  $list->insert ('end', $_)
    foreach @value;
    
  return;
} # setList

sub clearList($) {
  my ($list) = @_;

  return
    unless $list;

  $list->delete ('0.0', 'end');
  
  return;
} # clearList

sub search (@) {
  my (@values) = @_;

  return (undef, ())
    unless length $searchPattern;

  my ($index, @matches);

  # First filter @values including only matching entries
  foreach (@values) {
    push @matches, $_
      if /$searchPattern/i;
  } # foreach

  @values = ();

  # Now determine the first qualifying entry. Note if index is already set then
  # we do not need to recompute it. It was computed above via a Up or Down key.
  foreach (0 .. $#matches) {
    if ($matches[$_] =~ m/$searchPattern/i) {
      push @values, $matches[$_];
      $index = $_ unless defined $index;
    } # if
  } # foreach

  return ($index, @values);
} # search

sub setDropdown ($$$) {
  my ($listBox, $entry, $index) = @_;

  # Set listBox widget. This is actually the dropdown list.
  $listBox->see ($index);
  $listBox->activate ($index);

  # This should be the active entry to set into the entry widget
  my $currentEntry = $listBox->get ($index);

  # Set the entry widget. This is the line that the user is typing in
  $entry->delete (0, 'end');
  $entry->insert (0, $currentEntry);

  # Set the selection highlight (if the searchPattern is found)
  unless (length $searchPattern == 0) {
    if ($currentEntry =~ /$searchPattern/i) {
      $entry->selectionClear;
      $entry->selectionRange ($-[0], $+[0]);
      $entry->icursor ($+[0]);
    } # if
  } # unless
  
  return;
} # setDropdown

sub handleKeypress {
  my ($entry, $listBox) = @_;

  my (@matches, $match, $index);

  # This is ugly but works  
  my $browseEntry = $listBox->parent->parent;

  my $key    = $entry->XEvent->A;
  my $keysym = $entry->XEvent->K;

  debug "Entry: " . $entry->get;
  debug "Key: '$key' ($keysym)";

  # Map Cntl-n and Cntl-p to Down and Up
  $keysym = 'Down' if ord ($key) == 14;
  $keysym = 'Up'   if ord ($key) == 16;

  my $first  = 0;
  my $Last   = $listBox->index ('end') - 1; # Make 0 relative
  my $active = $listBox->index ('active');

  $index = $active;

  if ($keysym eq 'BackSpace') {
    $searchPattern = substr $searchPattern, 0, -1
      if length $searchPattern > 0;

    if (length $searchPattern == 0) {
      $index = 0;
      $entry->delete (0, 'end');
    } # if
  } elsif ($keysym eq 'Down') {
    if ($active < $Last) {
      setDropdown ($listBox, $entry, ++$active);
    } else {
      debug "Beep - no more down";
      $main->bell;
    } # if

    return;
  } elsif ($keysym eq 'Up') {
    if ($active > 0) {
      setDropdown ($listBox, $entry, --$active);
    } else {
      debug "Beep - no more up";
      $main->bell;
    } # unless

    return;
  } elsif ($keysym eq 'Tab') {
    $entry->selectionClear;

    return;
  } else {
    return if (!isprint ($key) || !ord ($key));

    $searchPattern .= $key;
  } # if

  debug "searchPattern: $searchPattern";

  # Get values based on the $browseEntry widget
  my @values;

  unless ($index) {
    do {
      if ($browseEntry == $pvobDropdown) {
        ($index, @values) = search sort @pvobs;
      } elsif ($browseEntry == $streamDropdown) {
        ($index, @values) = search sort @streams;
      } elsif ($browseEntry == $fromBaselineDropdown) {
       ($index, @values) = search sort @fromBaselines;
      } elsif ($browseEntry == $toBaselineDropdown) {
        ($index, @values) = search sort @toBaselines;
      } # if

      if (defined $index) {
        debug "Index: $index";
        $match = $values[$index];
      } else {
        debug "Index: <undefined>";
        debug "Length of searchPatern " . length $searchPattern;
        if (length $searchPattern == 0) {
          debug "Setting match to blank";
          $match = '';
          $index = 0;
        } else {
          debug "making searchPattern shorter";
          $searchPattern = substr $searchPattern, 0, -1;
          debug "Length of searchPatern now " . length $searchPattern;
        } # if
      } # if
    } until $match or length $searchPattern == 0;
  } # unless

  # Setting the listBox clears the active indicator so save it and reset it.
  $active = $listBox->index ('active');

  clearList $listBox;
  setList $listBox, sort @values;

  $listBox->activate ($active);

  if ($searchPattern) {
    if ($match and $match =~ /$searchPattern/i) {
      $entry->delete (0, 'end');
      $entry->selectionClear;
      $entry->insert (0, $match);
      $entry->icursor ($+[0]);
      $entry->selectionRange ($-[0], $+[0]);
    } else {
      debug "Beep - no matches";
      $main->bell;
      return;
    } # if
  } # if

  # Now update the assocated listBox.
  $listBox->selectionClear (0, 'end');
  $listBox->selectionSet   ($index, $index);

  # Makes it so that the entry selected above is centered in the drop down list.
  # So if you had say entries like 1, 2, 3, 4,... 10 and you hit '5', you'll see
  # '5' in the listBox entry but you really want to also shift it so that if you
  # hit the drop down arrow, 5, is the entry at the top of the drop down list.
  $listBox->see ($index);

  debug 'Entry: ' . $entry->get;
  
  return;
} # handleKeypress

sub Tkerror ($) {
  my ($msg) = @_;

  my $error = $main->DialogBox (
    -title    => 'Error',
    -buttons  => [ 'OK' ],
  );

  my $text = $error->add (
    'ROText',
    -width      => 65,
    -height     => 8,
    -font       => "Arial 8",
    -wrap       => 'word',
  )->pack (
    -fill       => 'both',
    -expand     => 1,
  );

  $text->insert ('end', $msg);

  $error->Show;
  
  return;
} # Tkerror

sub Tkmsg ($;$) {
  my ($msg, $sleep) = @_;

  if ($msgWidget) {
    $msgWidget->configure (-text => $msg);
    $msgWidget->update;

    if ($sleep) {
      return
        if $sleep < 0;

      sleep $sleep;
    } # if

    $msgWidget->configure (-text => '');
    $msgWidget->update;
  } # if
  
  return;
} # Tkmsg

sub about () {
  my $msg = "Utility to select baselines and provide a simple list of "
          . "activities or file/directory versions that differ between "
          . "two baselines.\n\n"
          . "Note you can save this list using the Save button or you can "
          . "right click on a line and select Clearcase operations.\n\n"
          . "Written by Andrew DeFaria <Andrew\@ClearSCM.com>";

  my $about = $main->DialogBox (
    -title      => "About $FindBin::Script V$VERSION",
    -buttons    => [ 'OK' ],
  );

  my $text = $about->add (
    'ROText',
    -width      => 65,
    -height     => 8,
    -font       => "Arial 8",
    -wrap       => 'word',
  )->pack;

  # Stop about dialog from resizing
  $about->bind (
    '<Configure>' => sub {
      my $e = $about->XEvent;

      $about->maxsize ($e->w, $e->h);
      $about->minsize ($e->w, $e->h);
    },
  );

  $text->insert ('end', $msg);

  $about->Show;
  
  return;
} # about

sub popupCCActions ($) {
  my ($widget, $xy) = @_;

  $widget->selectionClear (0, 'end');

  my $index = $widget->index ($xy);
  my $event = $widget->XEvent;

  if (defined $index) {
    $widget->selectionSet ($index);

    if ($MODE eq 'versions') {
      $versionsMenu->post ($widget->rootx + $event->x, $widget->rooty + $event->y);
    } else {
      $activitiesMenu->post ($widget->rootx + $event->x, $widget->rooty + $event->y);
    }
  } # if
  
  return;
} # popupCCActions

sub busy () {
  $main->Busy (-recurse => 1);
  $main->update;
  
  return;
} # busy

sub unbusy () {
  $main->Unbusy;
  $main->update;
  
  return;
} # unbusy

sub getPvobs {
  $main->Busy (-recurse => 1);

  my ($status, @output) = $Clearcase::CC->execute ('lsvob');

  @pvobs = ();

  foreach (grep { /\(ucmvob/ } @output) {
    my @tokens = split;

    my $pvob = $tokens[0] eq '*'
             ? Clearcase::vobname ($tokens[1])
             : Clearcase::vobname ($tokens[0]);

    push @pvobs, $pvob;
  } # foreach

  clearList $streamDropdown;       $SELECTED{stream}       = '';
            $streamDropdown->update;
  clearList $fromBaselineDropdown; $SELECTED{fromBaseline} = '';
            $fromBaselineDropdown->update;
  clearList $toBaselineDropdown;   $SELECTED{toBaseline}   = '';
            $toBaselineDropdown->update;
  clearList $output;

  clearList $pvobDropdown;
  setList $pvobDropdown, sort @pvobs;

  $main->Unbusy;
  
  return;
} # getPvobs

sub getStreams () {
  $main->Busy (-recurse => 1);

  $searchPattern = '';

  clearList $streamDropdown;

  $SELECTED{stream} = 'Getting streams...';

  $streamDropdown->update;

  my $pvob = Clearcase::vobname ($SELECTED{pvob});
  
  $CCDBService->connectToServer
    or error "Unable to connect to CCDBService", 1;
  
  my ($status, $streams) = $CCDBService->execute ("FindStream * $pvob");
  
  $CCDBService->disconnectFromServer;
  
  if ($status) {
    Tkerror "Unable to get streams (Status: $status)\n" . join ("\n", @$output); 
    return;
  } # if
  
  # First empty @streams of the old contents
  @streams = ();
  
  push @streams, $$_{name}
    foreach (@$streams);

  clearList $fromBaselineDropdown;
  clearList $toBaselineDropdown;

  $SELECTED{fromBaseline} = '';
  $SELECTED{toBaseline}   = '';

  $fromBaselineDropdown->update;
  $toBaselineDropdown->update;

  clearList $output;

  $SELECTED{stream} = '';
  
  setList $streamDropdown, sort @streams;

  $streamDropdown->focus;

  $main->Unbusy;
  
  return;
} # getStreams

sub getBaselines () {
  $main->Busy (-recurse => 1);

  $searchPattern = '';

  my $status;

  clearList $fromBaselineDropdown; 
  clearList $toBaselineDropdown;

  $SELECTED{fromBaseline} = 'Getting baselines...';
  $SELECTED{toBaseline}   = 'Getting baselines...';

  $fromBaselineDropdown->update;
  $toBaselineDropdown->update; 

  ($status, @fromBaselines) = $Clearcase::CC->execute 
    ("lsbl -short -stream $SELECTED{stream}\@$Clearcase::VOBTAG_PREFIX$SELECTED{pvob}");

  @toBaselines = @fromBaselines;

  clearList $fromBaselineDropdown;
  clearList $toBaselineDropdown;

  $SELECTED{fromBaseline} = '';
  $SELECTED{toBaseline}   = '';

  $fromBaselineDropdown->update;
  $toBaselineDropdown->update; 

  clearList $output;

  setList $fromBaselineDropdown, sort @fromBaselines;
  setList $toBaselineDropdown,   sort @toBaselines;

  $main->Unbusy;
  
  return;
} # getBaselines

sub saveList () {
  my @types = (
    ['Text Files', '.txt', 'TEXT'],
    ['All Files',   '*']
  );

  my $filename = $main->getSaveFile (
    -filetype         => \@types,
    -initialfile      => "$SELECTED{fromBaseline}.$SELECTED{toBaseline}.diffs",
    -defaultextension => '.txt',
  );

  return unless $filename;

  open my $file, '>', $filename
    or Tkmsg "Unable to open $filename for writing - $!", -1
    and return;

  foreach ($output->get (0, 'end')) {
    print $file "$_\n";
  } # foreach

  close $file;
  
  return;
} # saveList

sub childDeath () {
  my $pid = wait;

  display "$pid died";

  CORE::exit;
  
  return;
} # childDeath

local $SIG{CLD} = \&childDeath;
local $SIG{CHLD} = \&childDeath;

sub ccexec ($;$$) {
  my ($cmd, $parm1, $parm2) = @_;

  unless ($parm1) {
    my $selected = $output->curselection;

    return
      unless $selected;

    my $line = $output->get ($selected);

    if ($MODE eq 'versions') {
      # Need to add on the view tag prefix
      $cmd .= " $Clearcase::VIEWTAG_PREFIX/" . $::view->tag . $line;
    } else {
      $cmd .= " activity:$line\@";
      $cmd .= Clearcase::vobtag $SELECTED{pvob};
    } # if
  } else {
    $cmd .= " $parm1 $parm2";
  } # unless

  $main->Busy (-recurse => 1);

  if ($ARCH eq 'windows' or $ARCH eq 'cygwin') {
    $Clearcase::CC->execute ($cmd);
  } else {
    # Use fork/exec to allow CC processes to not cause us to block
    unless (fork) {
      $Clearcase::CC->execute ($cmd);
      CORE::exit;
    } # unless
  } # if

  $main->Unbusy;
  
  return
} # ccexec

sub findVersion ($$) {
  my ($element, $baseline) = @_;

  my $cmd = 'find ' . substr ($element, 1) . ' -directory ';
     $cmd .= "-version 'lbtype($baseline)' -print";
    
  my ($status, @output) = $Clearcase::CC->execute ($cmd);

  if ($status) {
    my $msg = "Unable to determine the version for $element ($baseline)";
    
    Tkerror join ("\n", "$msg (Status: $status)", "\n", @output);

    exit $status;
  } # if

  # Change these silly '\'s -> '/'s
  $output[0] =~ s/\\/\//g;
  
  my $version;
  
  if ($output[0] =~ /.*$Clearcase::SFX(.*)/) {
    $version = $1;
  } # if
  
  return $version
} # findVersion

sub compareToPrev () {
  my $selected = $output->curselection;

  return
    unless $selected;

  my $element = $output->get ($selected);

  # Need to add on the view tag prefix
  my $element1  = "$Clearcase::VIEWTAG_PREFIX/" . $::view->tag . $element;
  my $element2  = "$Clearcase::VIEWTAG_PREFIX/" . $::view->tag . $element;
  
  # Get into the view context 
  my $view_context = $Clearcase::VIEWTAG_PREFIX . '/' . $::view->tag;
  my $cwd          = getcwd;

  # For my Cygwin environment - translate that path back into a Windows path
  if ($ARCH eq 'cygwin') {
    my @cwd = `cygpath -w $cwd`;
    chomp @cwd;

    $cwd = $cwd[0];
  } # if

  my ($status, @output) = $Clearcase::CC->execute ("cd \"$view_context\"");

  Tkerror "Unable to set view context to $view_context (Status: $status)" . 
    join ("\n", @output)
    if $status;
    
  my $version;
    
  # Determine from baseline version
  $version   = findVersion $element, $SELECTED{fromBaseline};
  $element1 .= "$Clearcase::SFX$version";
     
  # Determine to baseline version
  $version   = findVersion $element, $SELECTED{toBaseline};
  $element2 .= "$Clearcase::SFX$version";

  ccexec 'diff -g', $element1, $element2;
  
  return;
} # compareToPrev

sub history () {
  ccexec 'lshist -g';
  
  return;
} # history

sub versionTree () {
  ccexec 'lsvtree -g';
  
  return;
} # versionTree

sub properties () {
  ccexec 'describe -g';
  
  return;
} # properties

sub displayLines () {
  clearList $output;

  my @lines = keys %LINES;
  
  if ($MODE eq 'activities') {
    @lines = grep {!/(deliver|rebase|tlmerge|integrate)/} @lines
      unless $INTEGRATIONACTIVITIES;
  } # if

  setList $output, sort @lines;
  
  my $msg = @lines > 0 ? @lines : 'No';
     $msg .= $MODE eq 'versions' ? ' Element' : ' Activit';

  if ($MODE eq 'versions') {
    $msg .= 's'
      if @lines != 1;
  } else {
    if (@lines != 1) {
      $msg .= 'ies';
    } else {
      $msg .= 'y';
    } # if
  } # if  

  Tkmsg $msg, 3;
  
  return;
} # displayLines

sub setFocus () {
  my ($entry) = @_;

  $searchPattern = '';
  $entry->icursor (0);
  
  return;
} # setFocus

sub createUI () {
  $main = MainWindow->new;

  # Set an icon image
  $main->iconimage ($main->Photo (-file => "$FindBin::Bin/diffbl.gif"))
    if -f "$FindBin::Bin/diffbl.gif";

  my $WIDTH = (length ($TITLE) + 1) * 10;

  $main->geometry ("${WIDTH}x600");
  $main->title ("$FindBin::Script V$VERSION");

  my @frame;

  for (my $i = 0; $i < 9; $i++) {
    $frame[$i] = $main->Frame->pack;
  } # for

  # Create versions popup menu
  $versionsMenu = $main->Menu (
    -tearoff    => 0,
  );

  $versionsMenu->add (
    'command',
    -label      => 'Compare to Prev',
    -command    => \&compareToPrev,
  );
  $versionsMenu->add (
    'command',
    -label      => 'History',
    -command    => \&history,
  );
  $versionsMenu->add (
    'command',
    -label      => 'Version Tree',
    -command    => \&versionTree,
  );
  $versionsMenu->add (
    'command',
    -label      => 'Properties',
    -font       => 'Arial 8 bold',
    -command    => \&properties,
  );
  
  # Create activities popup menu
  $activitiesMenu = $main->Menu (
    -tearoff    => 0,
  );

  $activitiesMenu->add (
    'command',
    -label      => 'Show Contributing Activities',
    -state      => 'disable',
    -command    => [ \&Tkerror, "Unimplemented" ],
  );
  $activitiesMenu->add (
    'command',
    -label      => 'Checkin All',
    -state      => 'disable',
    -command    => [ \&Tkerror, "Unimplemented" ],
  );
  $activitiesMenu->add (
    'command',
    -label      => 'Finish Activity',
    -state      => 'disable',
    -command    => [ \&Tkerror, "Unimplemented" ],
  );
  $activitiesMenu->add (
    'command',
    -label      => 'Properties',
    -font       => 'Arial 8 bold',
    -command    => \&properties,
  );  

  $frame[0]->Label (
    -font   => 'Arial 10 bold',
    -text   => $TITLE,
    -anchor => 'center',
  )->pack;

  $pvobDropdown = createDropdown (
    $frame[1], 
    'Project Vob',
    \$SELECTED{pvob},
    \&getStreams,
    \&getPvobs,
  );

  # Remove the Leave binding from $pvobDropDown
  $pvobDropdown->bind ('<FocusOut>', undef);

  $streamDropdown = createDropdown (
    $frame[2],
    'Stream',
    \$SELECTED{stream},
    \&getBaselines,
  );

  $streamDropdown->bind ('<FocusIn>', \&setFocus);

  $fromBaselineDropdown = createDropdown (
    $frame[3],
    'From baseline',
    \$SELECTED{fromBaseline},
  );

  $fromBaselineDropdown->bind ('<FocusIn>', \&setFocus);

  $toBaselineDropdown = createDropdown (
    $frame[4],
    'To baseline',
    \$SELECTED{toBaseline},
  );

  $toBaselineDropdown->bind ('<FocusIn>', \&setFocus);

  $frame[5]->Label (
    -text => 'Show:',
    -font => 'Arial 8 bold',
  )->pack (
    -side    => "left",
    -padx    => 5,
    -pady    => 5,
  );
  my $versionsToggle = $frame[5]->Radiobutton (
    -text     => 'Versions',
    -value    => 'versions',
    -variable => \$MODE,
    -command  => \&::compareBaselines,
  )->pack (
    -side    => "left",
    -padx    => 5,
    -pady    => 5,
  );
  my $activitiesToggle = $frame[5]->Radiobutton (
    -text     => 'Activities',
    -value    => 'activities',
    -variable => \$MODE,
    -command  => \&::compareBaselines,
  )->pack (
    -side    => "left",
    -padx    => 5,
    -pady    => 5,
  );
  
  # Toggle on activities
  $activitiesToggle->select;
  
  $integrationActivitiesCheck = $frame[5]->Checkbutton (
    -text     => 'Integration activities',
    -variable => \$INTEGRATIONACTIVITIES,
    -command  => \&displayLines,
  )->pack (
    -side    => "left",
    -padx    => 5,
    -pady    => 5,
  );
  
  $output = createList $frame[6];

  $msgWidget = $frame[7]->Label (
    -font => 'Arial 8 bold',
  )->pack;

  createButton $frame[8], 'About',   \&about;
  $compareButton = createButton $frame[8], 'Compare', \&::compareBaselines;
  createButton $frame[8], 'Save',    \&saveList;
  createButton $frame[8], 'Exit',    \&exit;

  # Now populate the streams
  getStreams;

  MainLoop;
  
  return;
} # createUI

1;
