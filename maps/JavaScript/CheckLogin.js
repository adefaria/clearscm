////////////////////////////////////////////////////////////////////////////////
//
// File:	$RCSFile$
// Revision:	$Revision: 1.1 $
// Description:	This JavaScript is included in the MAPS login form to check
//		the fields of the form.
// Author:	Andrew@DeFaria.com
// Created:	Fri Nov 29 14:17:21  2002
// Modified:	$Date: 2013/06/12 14:05:47 $
// Language:	JavaScript
//
// (c) Copyright 2000-2006, Andrew@DeFaria.com, all rights reserved.
//
////////////////////////////////////////////////////////////////////////////////
function validate (login) {
  with (login) {
    username = trim_trailing_spaces (username);

    if (username.value == "") {
      alert ("You must specify your Username!");
      username.focus ();
      return false;
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
  } // with

  return true;
} // validate
