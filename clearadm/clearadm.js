////////////////////////////////////////////////////////////////////////////////
//
// File:        $RCSfile: clearadm.js,v $
// Revision:    $Revision: 1.8 $
// Description: Javascript routines for Clearadm
// Author:      Andrew@ClearSCM.com
// Created:     Wed Dec 29 12:36:47 EST 2010
// Modified:    $Date: 2011/01/21 01:00:09 $
// Language:    JavaScript
//
// (c) Copyright 2010, ClearSCM, Inc., all rights reserved.
// 
////////////////////////////////////////////////////////////////////////////////
function getXMLHTTP () {
  try {
    return new XMLHttpRequest ();
  } catch (e)	{		
    try {			
      return new ActiveXObject ('Microsoft.XMLHTTP');
    } catch (e) {
      try {
        return new ActiveXObject ('Msxml2.XMLHTTP');
      } catch (e) {
        return false;
      } // try
    } // try
  } // try
} // getXMLHTTP

function updateTimestamp (system, elementID, filesystem) {
  var request = getXMLHTTP ();
  var script  = 'getTimestamp.cgi?system=' + system + '&elementID=' + elementID;
  
  var scaling = document.getElementById ('scalingFactor').value;
  
  if (scaling) {
  	script += '&scaling=' + scaling;
  } // if
  
  if (filesystem) {
    script += '&filesystem=' + filesystem; 
  } // if
  
  if (request) {
    request.onreadystatechange = function () {
      if (request.readyState == 4) {
        if (request.status == 200) {
          document.getElementById (elementID).innerHTML 
            = request.responseText;
        } // if
      } // if
    } // function

   request.open ('get', script, true);
   request.send (null);
  } else {
  	alert ('Unable to create XMLHTTP Request object');
  } // if
} // updateTimestamp

function updateSystem (system) {
	updateTimestamp (system, 'startTimestamp');
	updateTimestamp (system, 'endTimestamp');
} // updateSystem

function updateSystemLink (system) {
	document.getElementById ('systemLink').innerHTML 
	 = '<a href="systemdetails.cgi?system=' + system + '">System</a>';
	
	updateTimestamp (system, 'startTimestamp');
	updateTimestamp (system, 'endTimestamp');
} // updateSystemLink

function updateFilesystems (system) {
  var request = getXMLHTTP ();
  
  if (request) {
    request.onreadystatechange = function () {
      if (request.readyState == 4) {
        if (request.status == 200) {
          document.getElementById ('filesystems').innerHTML 
            = request.responseText;
        } // if
      } // if
    } // function

    request.open ('GET', 'getFilesystems.cgi?system=' + system, true);
    request.send (null);
  } else {
  	alert ('Unable to create XMLHTTP Request object');
  } // if
} // updateFilesystems

function updateFilesystem (system, filesystem) {
	updateTimestamp (system, 'startTimestamp', filesystem);
	updateTimestamp (system, 'endTimestamp',   filesystem);
} // updateFilesystem

function trimSpaces (str) {
  return str.replace (/^\s+|\s+$/g, '');
} // trimSpaces

function validEmailAddress (email) {
  var emailPattern = /^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$/;
  
  return emailPattern.test (email);  
} // validEmailAddress

function validateAlert (alertrec) {
	with (alertrec) {
    if (name.value == '') {
      alert ("You must specify the alert's name");
      name.focus ();
      return false;
    } // if
    
    if (who.value) {
	    if (!validEmailAddress (alertrec.who.value)) {
        alert ('That email address is invalid!\n'
            + 'Must be <username>@<domainname>\n'
            + 'For example: Andrew@ClearSCM.com');
        return false;
      } // if
    } // if
	} // with
} // validateAlert

function validateNotification (notification) {
  with (notification) {
  	if (name.value == '') {
  		alert ("You must specify the notification's name");
  		name.focus ();
  		return false;
  	} // if
  	
  	if (cond.value == '') {
  		alert ('You must specify a condition');
  		cond.focus ();
  		return false;
  	} // if
  } // with
} // validateNotification

function validateSchedule (schedule) {
  with (schedule) {
  	if (name.value == '') {
  		alert ("You must specify the schedule's name");
  		name.focus;
  		return false;
  	} // if
  	
    if (isNaN (nbr.value)) {
    	alert ('Frequency is not a number');
    	nbr.focus;
    	return false;
    } else if (nbr.value < 1 || nbr.value > 999) {
    	alert ('Frequency must be a positive number between 1-999');
    	nbr.focus;
    	return false;
    } // if
  } // with
} // validateSchedule

function validateTask (task) {
  with (task) {
  	if (name.value == '') {
  		alert ("You must specify the task's name");
  		name.focus;
  		return false;
  	} // if
  } // with
} // validateTask

function validateSystem (system) {
  with (system) {
    name.value = trimSpaces (name.value);
    
    if (name.value == '') {
      alert ("You must specify the system's name");
      name.focus ();
      return false;
    } // if
    
    admin.value = trimSpaces (admin.value);
    
    if (admin.value == '') {
      alert ("You must specify the admin's name");
      admin.focus ();
      return false;
    } // if
    
    if (isNaN (port.value)) {
    	alert ('Port is not a number');
    	port.focus;
    	return false;
    } else if (port.value < 1 || port.value > 65535) {
    	alert ('Port must be a positive number between 1-65535');
    	port.focus;
    	return false;
    } // if
    
    if (isNaN (loadavgThreshold.value)) {
    	alert ('Loadavg Threshold is not a number');
    	loadavgThreshold.focus;
    	return false;
    } else if (loadavgThreshold.value < 0 || loadavgThreshold.value > 99.99) {
    	alert ('Loadavg Threshold must be a positive number between 0 - 99.99');
    	loadavgThreshold.focus;
    	return false;
    } // if
    
    email.value = trimSpaces (email.value);
    
    if (email.value == '') {
      alert ("You must specify the admin's email");
      email.focus ();
      return false;
    } else {
    	if (!validEmailAddress (email.value)) {
    		alert ('That email address is invalid!\n'
 		        + 'Must be <username>@<domainname>\n'
            + 'For example: Andrew@ClearSCM.com');
     	  return false;
    	} // if
    } // if
  } // with
} // validateSystem

function AreYouSure (message) {
  return window.confirm (message);
} // AreYouSure