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
} // AdjustTableWidth

function checksearch(form) {
  if (form.str.value == "") {
    // Let normal validation handle empty (or just return false)
    // search.cgi handles empty string via DisplayError conventionally, 
    // but here we might want to pop up locally?
    // For now, let's just fetch count even if empty (will result in 0 or error)
    // Actually, DisplayError "No search string specified" is in search.cgi.
    // Let's mimic that behavior via alert/modal if we want, or just let server handle it?
    // User wants "dialog indicating nothing was found". 
    // If empty string -> Nothing matching (or error). 
    // Let's do the fetch.
  }

  var url = "/maps/bin/search.cgi?view=count&str=" + encodeURIComponent(form.str.value);

  // Use synchronous XHR or async with prevention?
  // Since we need to return false/true to the form submit, we MUST use async + manual submit,
  // OR just use fetch and manual submit.
  // Standard pattern: return false always, then if good, form.submit().
  
  fetch(url, { credentials: 'include' })
    .then(function(response) {
       return response.text();
    })
    .then(function(count) {
       if (parseInt(count) > 0) {
           // Matches found, proceed with actual submission
           // We need to bypass this handler to avoid loop. 
           // form.submit() bypasses onsubmit handler in standard HTML.
           form.submit();
       } else {
           // Nothing found, show modal
           showModal("ERROR: Nothing matching!", form.str);
       }
    })
    .catch(function(err) {
        console.error("Search check failed", err);
        // Fallback: submit anyway? Or show error?
        // showModal("Error checking search results", form.str);
    });

  return false; // Prevent default submission
}

function showModal(msg, inputToFocus) {
    var overlay = document.createElement('div');
    overlay.className = 'modal-overlay';
    
    var content = document.createElement('div');
    content.className = 'modal-content';
    
    // Simple message structure
    var msgP = document.createElement('p');
    msgP.innerText = msg;
    msgP.style.color = 'var(--text-color)'; // Ensure visibility
    
    var closeBtn = document.createElement('button');
    closeBtn.className = 'modal-btn';
    closeBtn.innerText = 'OK';
    
    // Handle Enter or Escape key to close
    var handleKey = function(e) {
        if (e.key === 'Enter' || e.key === 'Escape') {
            e.preventDefault();
            closeAndCleanup();
        }
    };
    document.addEventListener('keydown', handleKey);

    function closeAndCleanup() {
        if (document.body.contains(overlay)) {
            document.body.removeChild(overlay);
        }
        document.removeEventListener('keydown', handleKey);
        if (inputToFocus) {
            inputToFocus.value = '';
            inputToFocus.focus();
        }
    }

    // Cleanup listener on click close
    closeBtn.onclick = function() {
        closeAndCleanup();
    };
    
    content.appendChild(msgP);
    content.appendChild(closeBtn);
    overlay.appendChild(content);
    document.body.appendChild(overlay);
    
    // Close on overlay click
    overlay.addEventListener('click', function(e) {
        if (e.target === overlay) {
            closeAndCleanup();
        }
    });

    closeBtn.focus();
}
