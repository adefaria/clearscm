////////////////////////////////////////////////////////////////////////////////
//
// File:	CVSAdmUtils.js
// Description:	JavaScript routines for CVSAdm
// Author:	Andrew@DeFaria.com
// Created:	Wed May 12 13:47:39 PDT 2004
// Modified:
// Language:	JavaScript
//
// (c) Copyright 2005, Andrew@DeFaria.com, all rights reserved.
// 
////////////////////////////////////////////////////////////////////////////////
function trim_trailing_spaces (str) {
  // Strip trailing spaces
  while (str.value.substr (str.value.length - 1) == " ") {
    str.value = str.value.substr (0, (str.value.length - 1));
  } // while

  return str;
} // trim_trailing_spaces

function valid_email_address (email) {
  var email_regex = /.+@.+\..+/;

  return email_regex.test (email.value);
} // valid_email_address

function validate_login (login) {
  with (login) {
    userid = trim_trailing_spaces (userid);

    if (userid.value == "") {
      alert ("You must specify your Username!");
      userid.focus ();
      return false;
    } // if
  } // with

  return true;
} // validate_login

function validate_group (group) {
  with (group) {
    group = trim_trailing_spaces (group);

    if (group.value == "") {
      alert ("You must specify a group!");
      group.focus ();
      return false;
    } // if
  } // with

  return true;
} // validate_group

function validate_sysuser (sysuser) {
  with (sysuser) {
    sysuser = trim_trailing_spaces (sysuser);

    if (sysuser.value == "") {
      alert ("You must specify a sysuser!");
      sysuser.focus ();
      return false;
    } // if
  } // with

  return true;
} // validate_sysuser

function validate_user (user) {
  with (user) {
    if (typeof username != "undefined") {
      if (username.value == "") {
	alert ("You must specify a Username");
	username.focus ();
	return false;
      } // if
    } // if

    var password_msg = 
      "To change your password specify both your old and new passwords then\n" +
      "repeat your new password in the fields provided.\n\n" +
      "To leave your password unchanged leave old, new and repeated\n" +
      "password fields blank.";

    if (typeof old_password != "undefined") {
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
    } // if

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
  } // with

  return true;
} // validate_user

function AreYouSure (message) {
  return window.confirm (message);
} // AreYouSure
