////////////////////////////////////////////////////////////////////////////////
//
// File:	$RCSFile$
// Revision:	$Revision: 1.1 $
// Description:	This JavaScript performs some simple validations for the 
//		actions buttons on the list page.
// Author:	Andrew@DeFaria.com
// Created:	Fri Nov 29 14:17:21  2002
// Modified:	$Date: 2013/06/12 14:05:47 $
// Language:	JavaScript
//
// (c) Copyright 2000-2006, Andrew@DeFaria.com, all rights reserved.
//
////////////////////////////////////////////////////////////////////////////////
function CheckOnly1Checked (form) {
  var nbr_checked = 0;

  // Loop through form and count the number of checked boxes
  for (var i = 0; i < form.length; i++) {
    var e = form.elements [i];
    if (e.type == "checkbox" && e.checked) {
      nbr_checked++;
    } // if
  } // for

  if (nbr_checked == 1) {
    return true;
  } else if (nbr_checked > 1) {
    alert ("You can only have one item marked for this action");
    return false;
  } else {
    alert ("No lines were marked!");
    return false;
  } // if
} // CheckOnly1Checked

function CheckAtLeast1Checked (form) {
  var nbr_checked = 0;

  // Loop through form and count the number of checked boxes
  for (var i = 0; i < form.length; i++) {
    var e = form.elements [i];
    if (e.type == "checkbox" && e.checked) {
      nbr_checked++;
    } // if
  } // for

  if (nbr_checked > 0) {
    return true;
  } else {
    alert ("No lines were marked!");
    return false;
  } // if
} // CheckAtLeast1Checked

function NoneChecked (form) {
  var nbr_checked = 0;

  // Loop through form and count the number of checked boxes
  for (var i = 0; i < form.length; i++) {
    var e = form.elements [i];
    if (e.type == "checkbox" && e.checked) {
      nbr_checked++;
    } // if
  } // for

  if (nbr_checked == 0) {
    return true;
  } else {
    alert ("You must not have any checkboxes checked to perform this action");
    return false;
  } // if
} // NoneChecked

function AreYouSure (message) {
  return window.confirm (message);
} // AreYouSure

function ClearAll (form) {
  for (var i = 0; i < form.length; i++) {
    var e = form.elements [i];
    if (e.type == "checkbox" && e.checked) {
      e.checked = false;
    } // if
  } // for

  return false;
} // ClearAll

function CheckEntry (form) {
  var current_entry     = "";
  var current_entry_nbr = 0;

  var digits	= /[^\d]+(\d+)/;
  var parmname	= /([^\d]+)\d+/;

  for (var i = 0; i < form.length; i++) {
    var e = form.elements [i];
    if (e.type == "text") {
      var name = e.name;
      var parm = name.match (parmname);
      var nbr  = name.match (digits);
      if (current_entry_nbr == 0) {
	current_entry_nbr = nbr [1];
      } // if
      if (nbr [1] == current_entry_nbr) {
	if (parm [1] == "pattern" || parm [1] == "domain") {
	  current_entry = current_entry + e.value;
	} // if
      } else {
	if (current_entry == "") {
	  alert ("You must specify a value for Username and/or Domain for entry #" + current_entry_nbr);
	  return false;
	} // if
	current_entry_nbr = nbr [1];
	current_entry	  = e.value;
      } // if
    } // if
  } // for

  if (current_entry == "") {
    alert ("You must specify a value for Username and/or Domain for entry #" + current_entry_nbr);
    return false;
  } else {
    return true;
  } // if
} // CheckEntry

function ChangePage (page, type, lines) {
  window.location = "/maps/php/list.php" + "?type=" + type + "&next=" + page * lines;
} // ChangePage

