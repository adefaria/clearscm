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

  var url = "/maps/bin/checkaddress.cgi?view=fragment&sender=" + encodeURIComponent(form.email.value);
  if (user) {
    url = url + "&user=" + encodeURIComponent(user);
  }

  // Fetch the result and show in modal
  fetch(url, { credentials: 'include' })
    .then(function(response) {
       return response.text();
    })
    .then(function(html) {
       // Create modal DOM
       var overlay = document.createElement('div');
       overlay.className = 'modal-overlay';
       
       var content = document.createElement('div');
       content.className = 'modal-content';
       content.innerHTML = html;
       
       var closeBtn = document.createElement('button');
       closeBtn.className = 'modal-btn';
       closeBtn.innerText = 'Close';
       closeBtn.onclick = function() {
           document.body.removeChild(overlay);
       };
       
       // Handle Enter or Escape key to close
       var handleKey = function(e) {
           if (e.key === 'Enter' || e.key === 'Escape') {
               e.preventDefault();
               document.body.removeChild(overlay);
               document.removeEventListener('keydown', handleKey);
           }
       };
       document.addEventListener('keydown', handleKey);

       // Cleanup listener on click close
       var originalClose = closeBtn.onclick;
       var cleanup = function() {
           originalClose();
           document.removeEventListener('keydown', handleKey);
           
           // Clear and focus input
           if (form && form.email) {
               form.email.value = '';
               form.email.focus();
           }
       };
       
       closeBtn.onclick = cleanup;

       // Wrap button in a div to ensure it breaks to a new line
       var buttonContainer = document.createElement('div');
       buttonContainer.style.textAlign = 'center'; // Maintain center alignment
       buttonContainer.style.marginTop = '1rem';
       buttonContainer.appendChild(closeBtn);

       content.appendChild(buttonContainer);
       overlay.appendChild(content);
       document.body.appendChild(overlay);
       
       // Close on overlay click
       overlay.addEventListener('click', function(e) {
           if (e.target === overlay) {
               document.body.removeChild(overlay);
               document.removeEventListener('keydown', handleKey);
               // Also clear/focus on click-away
               if (form && form.email) {
                   form.email.value = '';
                   form.email.focus();
               }
           }
       });
       
       // Focus the close button for accessibility
       closeBtn.focus();
    })
    .catch(function(err) {
        console.error("CheckAddress failed", err);
        alert("Error checking address");
    });

  return false;
}
