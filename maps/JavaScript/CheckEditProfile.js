////////////////////////////////////////////////////////////////////////////////
//
// File:	$RCSFile$
// Revision:	$Revision: 1.1 $
// Description:	This JavaScript is included in the MAPS edit profile form to 
//		check the fields of the form.
// Author:	Andrew@DeFaria.com
// Created:	Fri Nov 29 14:17:21  2002
// Modified:	$Date: 2013/06/12 14:05:47 $
// Language:	JavaScript
//
// (c) Copyright 2000-2006, Andrew@DeFaria.com, all rights reserved.
//
////////////////////////////////////////////////////////////////////////////////
function validate (profile) {
  with (profile) {
    fullname = trim_trailing_spaces (fullname);
    if (fullname.value == "") {
      alert ("Full name is required!");
      fullname.focus ();
      return false;
    } // if

    email = trim_trailing_spaces (email);
    if (email.value == "") {
      alert ("We need your email address - in case you forget your password\nand we need to send it to you.");
      email.focus ();
      return false;
    } else {
      if (!valid_email_address (email)) {
	alert ("That email address is invalid!\nMust be <username>@<domainname>\nFor example: Andrew@DeFaria.com.");
	return false;
      } // if
    } // if

    var password_msg = 
      "To change your password specify both your old and new passwords then\n" +
      "repeat your new password in the fields provided\n\n" +
      "To leave your password unchanged leave old, new and repeated\n" +
      "password fields blank";

    if (old_password.value != "") {
      if (new_password.value == "") {
	alert (password_msg);
	new_password.focus ();
	return false;
      } else {
	if (new_password.value.length < 6) {
	  alert ("Passwords must be greater than 6 characters.");
	  new_password.focus ();
	  return false;
	} // if
      } // if
      if (repeated_password.value == "") {
	alert (password_msg);
	repeated_password.focus ();
	return false;
      } else {
	if (repeated_password.value.length < 6) {
	  alert ("Passwords must be greater than 6 characters.");
	  repeated_password.focus ();
	  return false;
	} // if
      } // if
      if (new_password.value != repeated_password.value) {
	alert ("Sorry but the new password and repeated password are not the same!");
	new_password.focus ();
	return false;
      } // if
    } else {
      if (new_password.value != "") {
	alert (password_msg);
	new_password.focus ();
	return false;
      } // if
      if (repeated_password.value != "") {
	alert (password_msg);
	repeated_password.focus ();
	return false;
      } // if
    } // if

    if (MAPSPOP [0].checked) {
      alert ("Sorry but MAPSPOP has not yet been implemented");
      return false;
    } // if

    if (tag_and_forward [0].checked) {
      alert ("Sorry but Tag & Forward has not yet been implemented");
      return false;
    } // if
  } // with

  return true;
} // validate
