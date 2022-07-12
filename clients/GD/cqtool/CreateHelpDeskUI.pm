##############################################################################
#
# Name: CreateHelpDeskUI.pm
#
# Description: CreateHelpDeskUI.pm is a Perl module that encapsulates
#	       a Perl/Tk application to create a Help Desk
#	       ticket. This application was developed for a few
#	       reasons. First ucmwb needs to be able to create Help
#	       Desk tickets. The approach was to use IBM/Rational's
#	       cqtool (/opt/rational/clearquest/bin/cqtool) but there
#	       is two problems with this. First IBM/Rational's cqtool
#	       is unsupported and documented. Secondly IBM/Rational's
#	       cqtool is going away as of Clearquest 7.0.
#
#	       Another problem is that while IBM/Rational's cqtool
#	       would work, it does not return the ID of the Help Desk ticket
#	       created!
#
#	       So this Perl/Tk module was created to create Help Desk
#	       tickets. Perl interfaces with Clearquest to call the
#	       appropraite Clearquest action hooks and the like. Note
#	       that only the basic information is asked for. If you
#	       really want to create or modify a full Help Desk ticket
#	       use Clearquest. This Perl/Tk app's main customer is
#	       ucmwb.
#
# Author: Andrew@ClearSCM.com
#
# (c) Copyright 2007, General Dynamics, all rights reserved
#
##############################################################################
use strict;
use warnings;

package CreateHelpDeskUI;
  use Tk;
  use Tk::Dialog;
  use Tk::BrowseEntry;

  use Display;
  use Tk::MyText;
  use CQTool;

  use base "Exporter";

  my $ME		= "CreateHelpDesk";
  my $VERSION		= "1.1";

  # Colors
  my ($EDIT_FOREGROUND, $EDIT_BACKGROUND);

  our %hd;

  our @EXPORT = qw (
    createHelpDeskUI
    %hd
  );

  # Globals
  my $_createHelpDeskUI;

  # Dropdowns
  my (
    $_requestor,
    $_location,
    $_category,
    $_related_version,
    $_platform,
    $_requestor_priority,
  );

  # Choice lists
  my (
    @_requestors,
    @_locations,
    @_categories,
    @_related_versions,
    @_platforms,
    @_requested_priorities,
  );

  # Buttons
  my $_submit;

  ############################################################################
  # Subroutines
  ############################################################################

  #---------------------------------------------------------------------------
  # _helpAbout (): Puts up the Help: About dialog box
  #---------------------------------------------------------------------------
  sub _helpAbout () {
    my $text = "$ME v$VERSION\n";

    $text .= <<END;

This application creates a Help Desk ticket using Perl/Tk. It is used by UCM/WB or can be used stand alone. It effectively replicates the functionality of Clearquest but 1) is blocking and 2) returns the RANCQ-# so that UCM/WB can determine the number of the newly created WOR.

Copyright General Dynamics © 2007 - All rights reserved
Developed by Andrew DeFaria <Andrew\@ClearSCM.com> of ClearSCM, Inc.
END

    my $desc = $_createHelpDeskUI->Dialog (
      -title		=> "About $ME",
      -text		=> $text,
      -buttons		=> [ "OK" ],
    );

    $desc->Show;
  } # _helpAbout

  #---------------------------------------------------------------------------
  # _displayValues (): Displays the contents for %hd hash
  #---------------------------------------------------------------------------
  sub _displayValues () {
    foreach (keys %hd) {
      if ($hd{$_}) {
        display "$_: $hd{$_}";
      } else {
        display "$_: undef";
      } # if
    } # foreach
  } # _displayValues

  #---------------------------------------------------------------------------
  # _getChoices (): For a given $entity and $fieldname, this routine returns
  #		    the given choice list from Clearquest.
  #---------------------------------------------------------------------------
  sub _getChoices ($$) {
    my ($entity, $fieldname) = @_;

    return @{$entity->GetFieldChoiceList ($fieldname)};
  } # _getChoices

  #---------------------------------------------------------------------------
  # _destroyHelpDeskUI (): Destroys the current HelpDesk UI recycling Tk
  #			   objects
  #---------------------------------------------------------------------------
  sub _destroyHelpDeskUI () {
    # Destroy all globals created
    destroy $_submit;
    destroy $_requestor;
    destroy $_location;
    destroy $_category;
    destroy $_related_version;
    destroy $_platform;
    destroy $_requestor_priority;
    destroy $_createHelpDeskUI;

    $_requestor			=
    $_location			=
    $_category			=
    $_related_version		=
    $_platform			=
    $_requestor_priority	=
    $_submit			=
    $_createHelpDeskUI		= undef;

    %hd = ();
  } # _destroyHelpDeskUI

  #---------------------------------------------------------------------------
  # _submit (): Actually creates the WOR given the filled out %hd hash.
  #---------------------------------------------------------------------------
  sub _submit () {
    debug "Creating Help Desk Ticket...";

    # Change requestor from a format of "lastname, firstname (badge)" -> badge
    if ($hd{requestor} =~ /\((\w*)\)$/) {
      $hd{requestor} = $1;
    } # if

    _displayValues if get_debug;

    my $new_id = CQTool::submitHelpDesk ($CQTool::entity, %hd);

    display $new_id if $new_id;

    _destroyHelpDeskUI;

    return $new_id;
  } # _submit

  #---------------------------------------------------------------------------
  # _setSubmitButton (): Sets the submit button to active only if all required
  #			 fields have values.
  #---------------------------------------------------------------------------
  sub _setSubmitButton (;$) {
    my ($headline) = @_;

    return if !$_submit;

    # Check to see if we can activate the submit button
    my $state = "normal";

    foreach (@CQTool::hd_required_fields) {
      if ($_ eq "headline") {
        if (defined $headline) {
	  if ($headline eq "") {
	    $state = "disable";
	    last;
	  } else {
	    next;
	  } # if
	} # if
      } # if

      if (!$hd{$_} or $hd{$_} eq "") {
	$state = "disable";
	last;
      } # if
    } # foreach

    $_submit->configure (
      -state	=> $state,
    );
  } # _setSubmitButton

  #---------------------------------------------------------------------------
  # _validateText (): Gets the text from the MyText widget and sets the submit
  #		      button
  #---------------------------------------------------------------------------
  sub _validatetext {
    my ($text) = @_;

    $hd{description} = $text->get_text;
    chomp $hd{description};

    _setSubmitButton $text;

    return 1;
  } # _validatetext

  #---------------------------------------------------------------------------
  # _validateEntry (): Gets the text from the headline widget and sets the
  # 		       submit button
  #---------------------------------------------------------------------------
  sub _validateentry {
    my ($entry) = @_;

    _setSubmitButton $entry;

    return 1;
  } # _validateentry

  #---------------------------------------------------------------------------
  # _createDropDown (): Creates a dropdown widget in $parent in a grid at the
  #			$x, $y coordinates with a $label and a $value, using
  #			dropdown @values and a $refresh procedure.
  #---------------------------------------------------------------------------
  sub _createDropDown ($$$$$$@) {
    my ($parent, $x, $y, $label, $refresh, $value, @values) = @_;

    $parent->Label (
      -width		=> length $label,
      -text		=> "$label:",
    )->grid (
      -row		=> $x,
      -column		=> $y,
      -sticky		=> "e",
    );

    return $parent->Optionmenu (
      -activeforeground	=> $EDIT_FOREGROUND,
      -activebackground	=> $EDIT_BACKGROUND,
      -command		=> \&$refresh,
      -variable		=> $value,
      -options		=> \@values,
    )->grid (
      -row		=> $x,
      -column		=> $y + 1,
      -sticky		=> "w",
    );
  } # _createDropDown

  #---------------------------------------------------------------------------
  # _createBrowseEntry (): Creates a dropdown like widget which drops down a
  #			   scrollable list in $parent with a $label, $refresh
  #			   procedure, setting $value with the choice from
  #			   @values.
  #---------------------------------------------------------------------------
  sub _createBrowseEntry ($$$$$$@) {
    my ($parent, $x, $y, $label, $refresh, $value, @values) = @_;

    $parent->Label (
      -width		=> length $label,
      -text		=> "$label:",
    )->grid (
      -row		=> $x,
      -column		=> $y,
      -sticky		=> "e",
    );

    my $longest_item = 0;

    foreach (@values) {
      $longest_item = length $_ if length $_ > $longest_item;
    } # if

    my $browse_entry = $parent->BrowseEntry (
      -browsecmd	=> \&$refresh,
      -variable		=> $value,
      -width		=> $longest_item,
    )->grid (
      -row		=> $x,
      -column		=> $y + 1,
      -sticky		=> "w",
    );

    my $i = 0;

    foreach (@values) {
      $browse_entry->insert ($i++, $_);
    } # foreach

    return $browse_entry;
  } # _createBrowseEntry

  #---------------------------------------------------------------------------
  # _createTextField (): Creates a text field widget in $parent with a $label
  #			 and a $value, using a $maxlen and a $validate
  #			 procedure.
  #---------------------------------------------------------------------------
  sub _createTextField ($$$$$) {
    my ($parent, $label, $value, $maxlen, $validate) = @_;

    $parent->Label (
      -text		=> "$label:",
      -justify		=> "right",
      -width		=> 10,
    )->pack (
      -side		=> "left",
      -anchor		=> "e",
    );

    $parent->Entry (
      -foreground	=> $EDIT_FOREGROUND,
      -background	=> $EDIT_BACKGROUND,
      -width		=> $maxlen,
      -justify		=> "left",
      -textvariable	=> $value,
      -validate		=> "key",
      -validatecommand	=> \&$validate,
    )->pack (
      -side		=> "left",
      -padx		=> 5,
      -anchor		=> "e",
    );
  } # _createTextField

  #---------------------------------------------------------------------------
  # _createText (): Creates a multiline text field widget in $parent with a
  #		    $label and a $value, using the specified $rows and $cols
  #		    and a $validate procedure.
  #---------------------------------------------------------------------------
  sub _createText ($$$$$$) {
    my ($parent, $label, $value, $rows, $cols, $validate) = @_;

    $parent->Label (
      -text		=> "$label:",
      -justify		=> "right",
      -width		=> 10,
    )->pack (
      -side		=> "left",+
      -anchor		=> "n",
      -pady		=> 5,
    );

    $parent->MyText (
      -foreground	=> $EDIT_FOREGROUND,
      -background	=> $EDIT_BACKGROUND,
      -height		=> $rows,
      -width		=> $cols,
      -modified		=> \&$validate,
      -text		=> $value,
    )->pack (
      -side		=> "left",
      -pady		=> 5,
      -anchor		=> "s",
    );
  } # _createText

  #---------------------------------------------------------------------------
  # _createButton (): Creates a pushbutton widget in $parent with a $label and
  #		      an $action.
  #---------------------------------------------------------------------------
  sub _createButton ($$$) {
    my ($parent, $label, $action) = @_;

    $parent->Button (
      -activeforeground	=> $EDIT_FOREGROUND,
      -activebackground	=> $EDIT_BACKGROUND,
      -text		=> $label,
      -width		=> length $label,
    -command		=> \$action
    )->pack (
      -side		=> "left",
      -padx		=> 5
    );
  } # _createButton

  #---------------------------------------------------------------------------
  # _changeDropDown (): Refreshes the values in the dropdown menu.
  #---------------------------------------------------------------------------
  sub _changeDropDown ($@) {
    my ($dropdown, @values) = @_;

    if ($dropdown) {
      my $menu = $dropdown->menu;

      if ($menu) {
	$dropdown->menu->delete (0, "end");
      } # if

      $dropdown->addOptions (@values);
    } # if
  } # _changeDropDown

  #---------------------------------------------------------------------------
  # _refresh (): Refreshes the application by getting news values from
  #		 Clearquest. Note a change in one dropdown may change others,
  #		 so we re-get all of them through this procedure.
  #---------------------------------------------------------------------------
  sub _refresh () {
    my $fieldname;

    $fieldname 			= "category";
    @_categories		= _getChoices $CQTool::entity, $fieldname;
    $hd{$fieldname}		= $_categories[0] if !$hd{$fieldname};
    $CQTool::entity->SetFieldValue ($fieldname, $hd{$fieldname});

    $fieldname 			= "related_version";
    @_related_versions	= _getChoices $CQTool::entity, $fieldname;
    $hd{$fieldname}		= $_related_versions[0] if !$hd{$fieldname};
    $CQTool::entity->SetFieldValue ($fieldname, $hd{$fieldname});

    $fieldname 			= "platform";
    @_platforms		= _getChoices $CQTool::entity, $fieldname;
    $hd{$fieldname}		= $_platforms[0] if !$hd{$fieldname};
    $CQTool::entity->SetFieldValue ($fieldname, $hd{$fieldname});

    $fieldname 			= "requestedpriority";
    @_requested_priorities	= _getChoices $CQTool::entity, $fieldname;
    $hd{$fieldname}		= $_requested_priorities[0] if !$hd{$fieldname};
    $CQTool::entity->SetFieldValue ($fieldname, $hd{$fieldname});

    _changeDropDown $_category,			@_categories;
    _changeDropDown $_related_version,		@_related_versions;
    _changeDropDown $_platform,			@_platforms;
    _changeDropDown $_requestor_priority,	@_requested_priorities;

    _setSubmitButton;
  } # _refresh

  #---------------------------------------------------------------------------
  # _getNames (): Translates an array of badge numbers into a hash of names
  #		  as the key and badge numbers as the value.
  #---------------------------------------------------------------------------
  sub _getNames (@) {
    my (@badges) = @_;

    my %names;

    foreach (@badges) {
      my $query = $CQTool::session->BuildQuery ("users");

      $query->BuildField ("fullname");

      my $filter = $query->BuildFilterOperator ($CQPerlExt::CQ_BOOL_OP_AND);

      # Clearquest requires values to be in an array
      my @badge = $_;

      $filter->BuildFilter ("login_name", $CQPerlExt::CQ_COMP_OP_EQ, \@badge);

      my $result = $CQTool::session->BuildResultSet ($query);

      $result->Execute;

      my $status = $result->MoveNext;

      my $fullname;

      while ($status == $CQPerlExt::CQ_SUCCESS) {
	$fullname = $result->GetColumnValue (1);
	$status = $result->MoveNext;
      } # while

      $names{$fullname ? $fullname : "<unknown>"} = $_;
    } # foreach

    return %names;
  } # _getNames

  #---------------------------------------------------------------------------
  # _darken (): Returns a slightly darker color than the passed in color
  #---------------------------------------------------------------------------
  sub _darken ($) {
    my ($color) = @_;

    # Get the RGB values
    my ($r, $g, $b) = $_createHelpDeskUI->rgb($color);

    # Set them to $DARKEN % of their previous values
    my $DARKEN = .8;
    my $rhex = sprintf "%x", $r * $DARKEN;
    my $ghex = sprintf "%x", $g * $DARKEN;
    my $bhex = sprintf "%x", $b * $DARKEN;

    # Return a color string
    return "\#$rhex$ghex$bhex";
  } # _darken

  #---------------------------------------------------------------------------
  # _createHelpDeskUI (): This is the main and exported routine that creates
  #			  and handles the entire Perl/Tk application for
  #			  creating a Help Desk ticket.
  #---------------------------------------------------------------------------
  sub createHelpDeskUI () {
    $_createHelpDeskUI = MainWindow->new;

    $EDIT_FOREGROUND	= $_createHelpDeskUI->optionGet ("foreground", "Foreground");
    $EDIT_BACKGROUND	= _darken ($_createHelpDeskUI->optionGet ("background", "Background"));

    $hd{id} = "None" if !$hd{id};

    $_createHelpDeskUI->title ("Submit Helpdesk $hd{id}");

    my $frame0 = $_createHelpDeskUI->Frame->pack (-pady => 2);
    my $frame1 = $_createHelpDeskUI->Frame->pack;
    my $frame2 = $_createHelpDeskUI->Frame->pack;
    my $frame3 = $_createHelpDeskUI->Frame->pack;
    my $frame4 = $_createHelpDeskUI->Frame->pack;
    my $frame5 = $_createHelpDeskUI->Frame->pack;
    my $frame6 = $_createHelpDeskUI->Frame->pack;

    _createTextField
      $frame1,
      "Headline",
      \$hd{headline},
      100,
      \&_validateentry;

    _createText
      $frame2,
      "Description",
      \$hd{description},
      24, 100,
      \&_validatetext;

    @_categories		= _getChoices $CQTool::entity, "category";
    @_related_versions	= _getChoices $CQTool::entity, "related_version";
    @_platforms		= _getChoices $CQTool::entity, "platform";
    @_requested_priorities	= _getChoices $CQTool::entity, "requestedpriority";
    @_requestors		= _getChoices $CQTool::entity, "requestor";

    my %requestor_names	= _getNames @_requestors;

    @_requestors = ();

    foreach (sort keys %requestor_names) {
      if ($_ eq "") {
	push @_requestors, "";
      } else {
	push @_requestors, "$_ ($requestor_names{$_})";
      } # if
    } # foreach

    @_locations		= _getChoices $CQTool::entity, "requestorlocation";

    $_requestor = _createBrowseEntry
      $frame3,
      0, 0,
      "Requestor",
      \&_refresh,
      \$hd{requestor},
      @_requestors;
    $_location = _createDropDown
      $frame3,
      0, 3,
      "Location",
      \&_refresh,
      \$hd{location},
      @_locations;

    $_category = _createDropDown
      $frame4,
      0, 0,
      "Category",
      \&_refresh,
      \$hd{category},
      @_categories;
    $_related_version = _createDropDown
      $frame4,
      0, 3,
      "Related Version",
      \&_refresh,
      \$hd{related_version},
      @_related_versions;

    $_platform = _createDropDown
      $frame5,
      0, 0,
      "Platform",
      \&_refresh,
      \$hd{platform},
      @_platforms;
    $_requestor_priority = _createDropDown
      $frame5,
      0, 3,
      "Requested Priority",
      \&_refresh,
      \$hd{requestedpriority},
      @_requested_priorities;

    $_submit = _createButton $frame6, "Submit", \&_submit;

    $_submit->configure (
      -state	=> "disabled",
    );

    _createButton $frame6, "Display",	\&_displayValues if (get_debug);
    _createButton $frame6, "About",	\&_helpAbout;
    _createButton $frame6, "Exit",	sub { _destroyHelpDeskUI };
  } # createHelpDeskUI

1;
