////////////////////////////////////////////////////////////////////////////////
//
// File:	$RCSFile$
// Revision:	$Revision: 1.1 $
// Description:	This JavaScript is included in the MAPS signup form to check
//		the fields of the form.
// Author:	Andrew@DeFaria.com
// Created:	Fri Nov 29 14:17:21  2002
// Modified:	$Date: 2013/06/12 14:05:47 $
// Language:	JavaScript
//
// (c) Copyright 2000-2006, Andrew@DeFaria.com, all rights reserved.
// 
////////////////////////////////////////////////////////////////////////////////
function validate (signup) {
  with (signup) {
    trim_trailing_spaces (userid);

    if (userid.value == "") {
      alert ("You must choose a name!");
      userid.focus ();
      return false;
    } // if

    if (userid.value.indexOf (" ") != -1) {
      alert ("Userids cannot contain spaces");
      userid.focus ();
      return false;
    } // if

    trim_trailing_spaces (fullname);

    if (fullname.value == "") {
      alert ("Full name is required!");
      fullname.focus ();
      return false;
    } // if

    if (email.value == "") {
      alert ("We need your email address - in case you forget " +
	     "your password\nand we need to send it to you.");
      email.focus ();
      return false;
    } else {
      var email_regex = /^\w+@\w+\.\w+$/;

      if (!valid_email_address (email)) {
	alert ("That email address is invalid!\n"	+
	       "Must be <username>@<domainname>\n"	+
	       "For example: Andrew@DeFaria.com.");
	return false;
      } // if
    } // if

    if (password.value == "") {
      alert ("You need to specify a password!");
      password.focus ();
      return false;
    } // if

    if (password.value.length < 6) {
      alert ("Passwords must be greater than 6 characters.");
      password.focus ();
      return false;
    } // if

    if (repeated_password.value == "") {
      alert ("Please repeat your password.");
      repeated_password.focus ();
      return false;
    } // if

    if (repeated_password.value.length < 6) {
      alert ("Passwords must be greater than 6 characters.");
      repeated_password.focus ();
      return false;
    } // if

    if (password.value != repeated_password.value) {
      alert ("Sorry but the password and repeated password are not the same!");
      password.focus ();
      return false;
    } // if

    if (MAPSPOP [0].checked) {
      alert ("Sorry but MAPSPOP has not be implemented yet!");
      return false;
    } // if

    if (tag_and_forward [0].checked) {
      alert ("Sorry but Tag & Forward has not be implemented yet!");
      return false;
    } // if
  } // with
   
  return true;
} // validate
