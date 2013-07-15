////////////////////////////////////////////////////////////////////////////////
//
// File:	$RCSFile$
// Revision:	$Revision: 1.1 $
// Description:	This JavaScript pops up a window for registerform.cgi
// Author:	Andrew@DeFaria.com
// Created:	Fri Nov 29 14:17:21  2002
// Modified:	$Date: 2013/06/12 14:05:47 $
// Language:	JavaScript
//
// (c) Copyright 2000-2006, Andrew@DeFaria.com, all rights reserved.
//
////////////////////////////////////////////////////////////////////////////////
function register () {
  var features = 
    "height=440"	+ "," +
    "location=no"	+ "," +
    "menubar=no"	+ "," +
    "status=no"		+ "," +
    "toolbar=no"	+ "," +
    "scrollbar=yes"	+ "," +
    "width=600";

  window.open (
    "http://earth:8080/maps/bin/registerform.cgi?userid=Andrew;sender=Andrew@DeFaria2.com",
    "register",
    features);
} // register
