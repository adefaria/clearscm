////////////////////////////////////////////////////////////////////////////////
//
// File:	$RCSFile$
// Revision:	$Revision: 1.1 $
// Description:	This JavaScript is included in the MAPS registration form
//		to check the fields of the form.
// Author:	Andrew@DeFaria.com
// Created:	Fri Nov 29 14:17:21  2002
// Modified:	$Date: 2013/06/12 14:05:47 $
// Language:	JavaScript
//
// (c) Copyright 2000-2006, Andrew@DeFaria.com, all rights reserved.
//
////////////////////////////////////////////////////////////////////////////////
function validate (subscription) {
  with (subscription) {
    fullname = trim_trailing_spaces (fullname);

    if (fullname.value == "") {
      alert ("You must tell us your real name!");
      fullname.focus ();
      return false;
    } // if

    sender = trim_trailing_spaces (sender);

    if (sender.value == "") {
      alert ("We need your email address!");
      sender.focus ();
      return false;
    } else {
      if (!valid_email_address (sender)) {
	alert ("That email address is invalid!\n"	+
	       "Must be <username>@<domainname>\n"	+
	       "For example: Andrew@DeFaria.com.");
	return false;
      } // if
    } // if
  } // with      

  return true;
} // validate
