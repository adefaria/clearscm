////////////////////////////////////////////////////////////////////////////////
//
// File:	$RCSFile$
// Revision:	$Revision: 1.1 $
// Description:	JavaScript routine to fix an IE bug regarding the user of
//		tables in <div>'s that are not flush right
// Author:	Andrew@DeFaria.com
// Created:	Wed May 12 13:47:39 PDT 2004
// Modified:	$Date: 2013/06/12 14:05:47 $
// Language:	JavaScript
//
// (c) Copyright 2000-2006, Andrew@DeFaria.com, all rights reserved.
//
////////////////////////////////////////////////////////////////////////////////
function AdjustTableWidth (table_name, width_percentage, margins) {
  // This function fixes the problem with IE and tables. When a table
  // is set to say 100% but is in a div that is not flush with the
  // left side of the browser window, IE does not take into account
  // the width of the div on the left. This function must be called
  // after the close of the div that the table is contained in. It
  // should also be called in the body tag for the onResize event in
  // case the browser window is resized.

  // If the browser is not IE and 5 or greater then return
  if (navigator.userAgent.indexOf ("MSIE") == -1 ||
      parseInt (navigator.appVersion) >= 5) {
    return;
  } // if

  // If width_percentage was not passed in then set it to 100%
  if (width_percentage == "" || width_percentage == null) {
    width_percentage = 1;
  } else {
    width_percentage = width_percentage / 100;
  } // if

  // If margins were not set then use 15 pixels
  if (margins == "" || margins == null) {
    margins = 15;
  } // if

  // Get table name
  var table = document.getElementById (table_name);

  if (table == null) {
    return; // no table, nothing to do!
  } // if

  // Get the width of the page in the browser
  var body_width = document.body.clientWidth;
 
  // Get the width of the left portion. Note this is hardcoded to the
  // value of "leftbar" for the MAPS application
  var sidebar_width = document.getElementById ("leftbar").clientWidth;

  // Now compute the new table width by subtracting off the sizes of
  // the sidebar_width and margins then multiply by the
  // width_percentage
  table.style.width = 
    (body_width - sidebar_width - margins) * width_percentage;
;} // AdjustTableWidth
