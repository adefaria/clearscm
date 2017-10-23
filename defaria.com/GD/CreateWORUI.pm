##############################################################################
#
# Name: CreateWORUI.pm
#
# Description: CreateWORUI.pm is a Perl module that encapsulates a
#	       Perl/Tk application to create a WOR. This application
#	       was developed for a few reasons. First ucmwb needs to
#	       be able to create WORs. The approach was to use
#	       IBM/Rational's cqtool
#	       (/opt/rational/clearquest/bin/cqtool) but there is two
#	       problems with this. First IBM/Rational's cqtool is
#	       unsupported and documented. Secondly IBM/Rational's
#	       cqtool is going away as of Clearquest 7.0.
#
#	       Another problem is that while IBM/Rational's cqtool
#	       would work, it does not return the ID of the WOR
#	       created!
#
#	       So this Perl/Tk module was created to create WORs. Perl
#	       interfaces with Clearquest to call the appropraite
#	       Clearquest action hooks and the like. Note that only
#	       the basic information is asked for. If you really want
#	       to create or modify a full WOR use Clearquest. This
#	       Perl/Tk app's main customer is ucmwb.
#
# Author: Andrew@ClearSCM.com
#
# (c) Copyright 2007, General Dynamics, all rights reserved
#
##############################################################################
use strict;
use warnings;

package CreateWORUI;
  use Tk;
  use Tk::Dialog;
  use Tk::MyText;

  use Display;
  use CQTool;

  use base "Exporter";

  my $ME		= "CreateWOR";
  my $VERSION		= "1.1";

  # Colors
  my ($EDIT_FOREGROUND, $EDIT_BACKGROUND);

  our %wor;

  our @EXPORT = qw (
    createWORUI
    %wor
  );

  # Globals
  my $_createWORUI;

  # Dropdowns
  my (
    $_projects,
    $_rclcs,
    $_prod_arch1s,
    $_prod_arch2s,
    $_engr_targets,
    $_work_codes,
    $_work_products,
    $_wor_classes,
  );

  # Choice lists
  my (
    @_projects,
    @_rclcs,
    @_prod_arch1s,
    @_prod_arch2s,
    @_engr_targets,
    @_work_codes,
    @_work_products,
    @_wor_classes,
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

This application creates a WOR using Perl/Tk. It is used by UCM/WB or can be used stand alone. It effectively replicates the functionality of Clearquest but 1) is blocking and 2) returns the RANCQ # so that UCM/WB can determine the number of the newly created WOR.

Copyright General Dynamics © 2007 - All rights reserved
Developed by Andrew DeFaria <Andrew\@ClearSCM.com> of ClearSCM, Inc.
END

    my $desc = $_createWORUI->Dialog (
      -title		=> "About $ME",
      -text		=> $text,
      -buttons		=> [ "OK" ],
    );

    $desc->Show ();
  } # _helpAbout

  #---------------------------------------------------------------------------
  # _displayValues (): Displays the contents for %wor hash
  #---------------------------------------------------------------------------
  sub _displayValues () {
    foreach (keys %wor) {
      if ($wor{$_}) {
        display ("$_: $wor{$_}");
      } else {
        display ("$_: undef");
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
  # _destroyCreateWORUI (): Destroys the current WOR UI recycling Tk objects
  #---------------------------------------------------------------------------
  sub _destroyCreateWORUI () {
    # Destroy all globals created
    destroy $_submit;
    destroy $_projects;
    destroy $_rclcs;
    destroy $_prod_arch1s;
    destroy $_prod_arch2s;
    destroy $_engr_targets;
    destroy $_work_codes;
    destroy $_work_products;
    destroy $_createWORUI;

    $_submit		=
    $_projects		=
    $_rclcs		=
    $_prod_arch1s	=
    $_prod_arch2s	=
    $_engr_targets	=
    $_work_codes	=
    $_work_products	=
    $_wor_classes	=
    $_createWORUI	= undef;

    %wor = ();
  } # _destroyCreateWORUI

  #---------------------------------------------------------------------------
  # _submit (): Actually creates the WOR given the filled out %wor hash.
  #---------------------------------------------------------------------------
  sub _submit () {
    debug "Creating WOR...";
    _displayValues if get_debug;
    my $new_id = CQTool::submitWOR ($CQTool::entity, %wor);

    display ($new_id) if $new_id;

    _destroyCreateWORUI;

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

    foreach (@CQTool::wor_required_fields) {
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

      if (!$wor{$_} or $wor{$_} eq "") {
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
  sub _validateText {
    my ($text) = @_;

    $wor{description} = $text->get_text;
    chomp $wor{description};

    _setSubmitButton $text;

    return 1;
  } # _validateText

  #---------------------------------------------------------------------------
  # _validateEntry (): Gets the text from the headline widget and sets the
  # 		       submit button
  #---------------------------------------------------------------------------
  sub _validateEntry {
    my ($entry) = @_;

    _setSubmitButton $entry;

    return 1;
  } # _validateEntry

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

    # Color the active foreground otherwise it's defaulted to ugly grey!
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

    $fieldname 		= "project";
    my %projects	= CQTool::getProjects $CQTool::session;
    $wor{$fieldname}	= $_projects[0] if !$wor{fieldname};
    $CQTool::entity->SetFieldValue ($fieldname, $wor{$fieldname});

    $fieldname		= "prod_arch1";
    @_prod_arch1s	= _getChoices $CQTool::entity, $fieldname;
    $wor{$fieldname}	= $_prod_arch1s[0] if !$wor{$fieldname};
    $CQTool::entity->SetFieldValue ($fieldname, $wor{$fieldname});

    $fieldname		= "prod_arch2";
    @_prod_arch2s	= _getChoices $CQTool::entity, $fieldname;
    $wor{$fieldname}	= $_prod_arch2s[0] if !$wor{$fieldname};
    $CQTool::entity->SetFieldValue ($fieldname, $wor{$fieldname});

    $fieldname		= "rclc_name";
    @_rclcs		= @{$projects{$wor{project}}};
    $wor{$fieldname}	= $_rclcs[0] if !$wor{$fieldname};
    $CQTool::entity->SetFieldValue ($fieldname, $wor{$fieldname});

    $fieldname		= "engr_target";
    @_engr_targets	= _getChoices $CQTool::entity, $fieldname;
    $wor{$fieldname}	= $_engr_targets[0] if !$wor{$fieldname};
    $CQTool::entity->SetFieldValue ($fieldname, $wor{$fieldname});

    $fieldname		= "work_code_name";
    @_work_codes	= _getChoices $CQTool::entity, $fieldname;
    $wor{$fieldname}	= $_work_codes[0] if !$wor{$fieldname};
    $CQTool::entity->SetFieldValue ($fieldname, $wor{$fieldname});

    $fieldname		= "work_product_name";
    @_work_products	= _getChoices $CQTool::entity, $fieldname;
    $wor{$fieldname}	= $_work_products[0] if !$wor{$fieldname};
    $CQTool::entity->SetFieldValue ($fieldname, $wor{$fieldname});

    _changeDropDown ($_projects,	keys %projects);
    _changeDropDown ($_rclcs,		@_rclcs);
    _changeDropDown ($_prod_arch1s,	@_prod_arch1s);
    _changeDropDown ($_prod_arch2s,	@_prod_arch2s);
    _changeDropDown ($_engr_targets,	@_engr_targets);
    _changeDropDown ($_work_codes,	@_work_codes);
    _changeDropDown ($_work_products,	@_work_products);

    _setSubmitButton ();
  } # _refresh

  #---------------------------------------------------------------------------
  # _darken (): Returns a slightly darker color than the passed in color
  #---------------------------------------------------------------------------
  sub _darken ($) {
    my ($color) = @_;

    # Get the RGB values
    my ($r, $g, $b) = $_createWORUI->rgb($color);

    # Set them to $DARKEN % of their previous values
    my $DARKEN = .8;
    my $rhex = sprintf "%x", $r * $DARKEN;
    my $ghex = sprintf "%x", $g * $DARKEN;
    my $bhex = sprintf "%x", $b * $DARKEN;

    # Return a color string
    return "\#$rhex$ghex$bhex";
  } # _darken

  #---------------------------------------------------------------------------
  # createWORUI (): This is the main and exported routine that creates and
  #		    handles the entire Perl/Tk application for creating a
  #		    WOR.
  #---------------------------------------------------------------------------
  sub createWORUI () {
    $_createWORUI = MainWindow->new;

    $EDIT_FOREGROUND	= $_createWORUI->optionGet ("foreground", "Foreground");
    $EDIT_BACKGROUND	= _darken ($_createWORUI->optionGet ("background", "Background"));

    $wor{id} = "None" if !$wor{id};

    $_createWORUI->title ("Submit WOR $wor{id}");

    my $frame0 = $_createWORUI->Frame->pack (-pady => 2);
    my $frame1 = $_createWORUI->Frame->pack;
    my $frame2 = $_createWORUI->Frame->pack;
    my $frame3 = $_createWORUI->Frame->pack;
    my $frame4 = $_createWORUI->Frame->pack;

    _createTextField (
      $frame1,
      "Headline",
      \$wor{headline},
      100,
      \&_validateEntry
    );

    _createText (
      $frame2,
      "Description",
      \$wor{description},
      24, 100,
      \&_validateText
    );

    my %projects = CQTool::getProjects ($CQTool::session);
    @_projects = keys %projects;

    $_projects = _createDropDown (
      $frame3,
      0, 0,
      "Project",
      \&_refresh,
      \$wor{project},
      @_projects
    );
    $_rclcs = _createDropDown (
      $frame3,
      0, 3,
      "Revision Control Life Cycle",
      \&_refresh,
      \$wor{rclc_name},
      @_rclcs
    );

    $_prod_arch1s = _createDropDown (
      $frame3,
      2, 0,
      "Product Architecture 1",
      \&_refresh,
      \$wor{prod_arch1},
      @_prod_arch1s
    );
    $_engr_targets = _createDropDown (
      $frame3,
      2, 3,
      "Engineering Target",
      \&_refresh,
      \$wor{engr_target},
      @_engr_targets
    );

    $_prod_arch2s = _createDropDown (
      $frame3,
      4, 0,
      "Product Architecture 2",
      \&_refresh,
      \$wor{prod_arch2},
      @_prod_arch2s
    );
    $_work_codes = _createDropDown (
      $frame3,
      4, 3,
      "Work Code",
      \&_refresh,
      \$wor{work_code_name},
      @_work_codes
    );

    $_work_products = _createDropDown (
      $frame3,
      6, 0,
      "Work Product",
      \&_refresh,
      \$wor{work_product_name},
      @_work_products
    );

    my $fieldname	= "wor_class";
    @_wor_classes	= _getChoices $CQTool::entity, $fieldname;
    $wor{$fieldname}	= "Worker";
    $CQTool::entity->SetFieldValue ($fieldname, $wor{$fieldname});

    $_wor_classes = _createDropDown (
      $frame3,
      6, 3,
      "WOR Class",
      sub {},
      \$wor{wor_class},
      @_wor_classes
    );

    # Default WOR Class to Worker
    $_wor_classes->setOption ("Worker");

    $_submit = _createButton ($frame4, "Submit", \&_submit);

    $_submit->configure (
      -state	=> "disabled",
    );

    _createButton ($frame4, "Display",	\&_displayValues) if (get_debug);
    _createButton ($frame4, "About",	\&_helpAbout);
    _createButton ($frame4, "Exit",	\&_destroyCreateWORUI);
  } # createWORUI

1;
