////////////////////////////////////////////////////////////////////////////////
//
// File:	$RCSFile$
// Revision:	$Revision: 1.1 $
// Description:	This JavaScript pops up a window for checkaddress.cgi
// Author:	Andrew@DeFaria.com
// Created:	Fri Nov 29 14:17:21  2002
// Modified:	$Date: 2013/06/12 14:05:47 $
// Language:	JavaScript
//
// (c) Copyright 2000-2006, Andrew@DeFaria.com, all rights reserved.
//
////////////////////////////////////////////////////////////////////////////////
function checkaddress (form, user) {
  if (form.email.value == "") {
    alert ("Enter an address to check");
    return false;
  }

  var features = 
    "height=200"	+ "," +
    "location=no"	+ "," +
    "menubar=no"	+ "," +
    "status=no"		+ "," +
    "toolbar=no"	+ "," +
    "scrollbar=yes"	+ "," +
    "width=400";

  var url = "/maps/bin/checkaddress.cgi?";

  if (user) {
    url = url + "user=" + user + ";";
  } // if

  url = url + "sender=" + form.email.value;

  window.open (url, "checkaddress", features);

  return false;
}
