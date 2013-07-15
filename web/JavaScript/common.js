////////////////////////////////////////////////////////////////////////////////
//
// File:        common.js
// Description: Common Javascript functions
// Author:      Andrew@DeFaria.com
// Created:     Thu Oct  6 14:16:05 PDT 2011
// Language:    javascript
//
////////////////////////////////////////////////////////////////////////////////
function basename (path) {
  return path.replace (/\\/g, '/').replace (/.*\//, '');
} // basename
 
function dirname (path) {
  return path.replace (/\\/g, '/').replace (/\/[^\/]*$/, '');
} // dirname

function getText (item) {
  // There's this annoying thing about getting the text of an HTML object - both
  // Chrome and IE use innerText but Firefox uses textContent.
  return item.innerText ? item.innerText : item.textContent;
} // getText

function getVar (variable) {
  var query = window.location.search.substring (1);
  
  var vars = query.split ('&');
  
  for (var i=0; i < vars.length; i++) {
    var pair = vars[i].split ('=');
    
    if (pair[0] == variable) {
      return pair[1];
    } // if
  } // for
  
  return null;
} // getVar

function keys (obj) {
  // keys: Emulate Perl's keys function. Note that hashes in Javascript are
  // implemented as associative arrays, which are really objects. There is no
  // keys function and as an Objects there are functions in there. So we use the
  // hasOwnProperty function to insure that this is a pproperty and not a 
  // method.
  var keys = [];

  for (key in obj) {
    if (obj.hasOwnProperty (key)) keys.push (key);
  } // for

  return keys;
} // keys

function objLength (object) {
  // The .length property doesn't exist for JavaScript objects and associative
  // arrays. You need to count the properties instead.
  var count = 0;
  
  for (property in object) {
    if (object.hasOwnProperty (property)) {
      count++;
    } // if
  } // for
  
  return count;
} // objLength