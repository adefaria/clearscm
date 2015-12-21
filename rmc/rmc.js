var comments;
var files;

function setOptions () {
  comments = document.getElementById ("comments").checked;
  files    = document.getElementById ("files").checked;
  //group    = document.getElementById ("group").checked;
} // setOptions

function colorLines () {
  return; // not used
  if (comments || files) {
    color = '#ffc';
  } else {
    color = 'white';
  } // if
  
  i = 1;
  
  while (element = document.getElementById (i++)) {
    element.style.backgroundColor = color;
  } // while
} // colorLines

function hideElement (elementName) {
  var i = 0;
  
  while ((element = document.getElementById (elementName + i++)) != null) {
    element.style.display = "none";
  } // while
} // hideElement

function showElement (elementName) {
  var i = 0;

  while ((element = document.getElementById (elementName + i++)) != null) {
    element.colSpan = 7;
    element.style.display = "";
  } // while
} // showElement

function toggleOption (option) {
  if (option == "comments") {
    if (comments) {
      hideElement (option);
      
      comments = false;
    } else {
      showElement (option);
      
      comments = true;
    } // if
  } else if (option == "files") {
    if (files) {
      hideElement (option);
      
      files = false;
    } else {
      showElement (option);
      
      files = true;
    } // if
  } // if
  
  //colorLines ();
} // toggleOption

function groupIndicate () {
  var fields = ['bugzilla', 'changelist', 'userid', 'summary'];
  var values = [];
  
  // Seed values
  for (var i = 0; i < fields.length; i++) {
    values[fields[i]] = document.getElementById (fields[i] + 1).innerHTML;
  } // for
  
  i = 1;
  
  while (document.getElementById (i) != null) {
    i++;
    
    for (var j = 0; j < fields.length; j++) {
      var element =  document.getElementById (fields[j] + i);
      
      if (element == null) break;
      
      if (group) {
        if (element.innerHTML == values[fields[j]]) {
          element.innerHTML = '';
        } else {
          values[fields[j]] = element.innerHTML;
        } // if
      } else {
        if (element.innerHTML == '') {
          element.innerHTML = values[fields[j]];
        } // if
      } // if
    } // for
  } // while
  
  // Toggle group
  if (group) {
    group = false;
  } else {
    group = true;
  } // if
} // groupIndicate