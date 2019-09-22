// Javascript functions to support operations in MAT-file comparison reports

// Copyright 2010-2013 The MathWorks, Inc.

// Getting the root window is browser dependent.  On some platforms the
// parent of root is the window, and window.window is window.
// On other browsers, parent can be undefined.
function getRootWindow() {
  if (parent) {return parent.window;} else {return window;}
}

function openvar(side,varname) {
  var rootWindow=getRootWindow();
  if (side=="left") {
    rootWindow.location="matlab:comparisons_private('matview','"+LEFT_FILE+"','"+varname+"','_left')";
  } else {
    rootWindow.location="matlab:comparisons_private('matview','"+RIGHT_FILE+"','"+varname+"','_right')";
  }
}

function mergeleft(varname) {
  var rootWindow=getRootWindow();
  rootWindow.location="matlab:comparisons_private('varmerge','"+RIGHT_FILE+"','"+LEFT_FILE+"','"+varname+"','"+REPORT_ID+"')";
}

function mergeright(varname) {
  var rootWindow=getRootWindow();
  rootWindow.location="matlab:comparisons_private('varmerge','"+LEFT_FILE+"','"+RIGHT_FILE+"','"+varname+"','"+REPORT_ID+"')";
}

function comparevar(varname) {
  var rootWindow=getRootWindow();
  rootWindow.location="matlab:comparisons_private('varcomp','"+LEFT_FILE+"','"+RIGHT_FILE+"','"+varname+"')";
}

