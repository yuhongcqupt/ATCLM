// Javascript functions to support navigation and highlighting in
// text file comparison reports.

// Copyright 2009-2013 The MathWorks, Inc.

// Getting the root window is browser dependent.  On some platforms the
// parent of root is the window, and window.window is window.
// On other browsers, parent can be undefined.
function getRootWindow() {
    if (parent) {return parent.window;} else {return window;}
}

// Returns true if the current renderer is ICE browser.
function ice() {
  return navigator.__ice_version;
}

// Variable LEFT_FILE must be defined (as a string) in the page which
// includes this file.
function openleft(lineNumber) {
    var rootWindow = getRootWindow();
    rootWindow.location = "openfile:left@" + lineNumber;
}

// Variable RIGHT_FILE must be defined (as a string) in the page which
// includes this file.
function openright(lineNumber) {
    var rootWindow = getRootWindow();
    rootWindow.location = "openfile:right@" + lineNumber;
}

function openLeftFile() {
    var rootWindow = getRootWindow();
    rootWindow.location = "openfile:left";
}

function openRightFile() {
    var rootWindow = getRootWindow();
    rootWindow.location = "openfile:right";
}

// Scrolls to the element with the specified "id" property and highlights it.
function scroll(section_id) {
    var rootWindow=getRootWindow();
    var section = document.getElementById(section_id);
    setcurrent(section,true);
}

// The currently highlighted node.
var CURRENT_SECTION = null;

function select(section_id) {
    var rootWindow=getRootWindow();
    var section = document.getElementById(section_id);
    setcurrent(section,false);
}

// Scrolls to the specified node and highlights it.
// Highlighting occurs only for nodes which have an "id" property starting
//  with the string "diff".
function setcurrent(section,do_scroll) {
    if (CURRENT_SECTION != null) {
        $(CURRENT_SECTION).removeClass('selected');
    };
    
    if (section != null) {
        CURRENT_SECTION = section;
        if (section.id.substring(0,4)=='diff') {
            // Don't highlight "top" or "bottom"
            $(CURRENT_SECTION).addClass('selected');
        }
        if (do_scroll) {
            scrollToMakeVisible(CURRENT_SECTION);
        }
    } else {
        CURRENT_SECTION = null;
    }
}

// Variable LAST_DIFF_ID must be defined in the page which includes this
// file.  It is a string of the form "diffX", where X is a number, and is the
// highest number of "diff" tag that appears within the body of the page.
// This tells us where to go if the user clicks the "Previous" button when
// already at the top.

// Navigates to the next change in the diff report.
// This is done by incrementing the number in the current section, which
// is assumed to have an "id" string of the form "diff99".
function goNext() {
    if (CURRENT_SECTION != null) {
        var id = CURRENT_SECTION.id;
        if (id == LAST_DIFF_ID) {
            scroll("diff0");
        } else {
            val = parseInt(id.substring(4));
            var newid = "diff" + (val+1);
            scroll(newid);
        }
    } else {
        // No current section.  Navigate to the first section.
        scroll("diff0");
    }
}

// Navigates to the previous change in the diff report, using the same
// approach as goNext().
function goPrevious() {
    if (CURRENT_SECTION != null) {
        var id = CURRENT_SECTION.id;
        var val = parseInt(id.substring(4));
        if (val > 0) {
            var newid = "diff" + (val-1);
            scroll(newid);
            return;
        }
    }
    // We didn't manage to go up.  Go to the bottom instead.
    scroll(LAST_DIFF_ID);
}

// Makes the specified node visible on the screen, positioning
// it 15% of the way down the window.
function scrollToMakeVisible(section) {
    var windowSize = $(window).height();
    
    // Scroll so that the "current" diff starts 15% of the way down
    // the screen.
    var elementOffset = $(section).offset().top;
    var restFrameOffset = 0.15*windowSize;
    $(window).scrollTop(elementOffset - restFrameOffset);
}

function getHtmlTextToSave() {
    // Cloning tags that contain scripts doesn't work in IE.  This means we
    // need to clone only the tags we need in the head and then assemble
    // the page back together
    
    // We only need the <meta>, <title> and <style type=text/css> tags
    var $newHead = $('<head></head>');
    $newHead.append($('meta').clone());
    $newHead.append($('title').clone());
    $newHead.append($('style[type*="text/css"]').clone());
    
    var bodyCopy = $('body').clone();
    var $bodyCopy = $(bodyCopy);
    
    // Replace all hyperlinks in the body
    $bodyCopy.find('a').each(function(){
        $(this).removeAttr('href');
    });
    
    // Remove leftText and righText nodes
    $bodyCopy.find('#leftText').remove();
    $bodyCopy.find('#rightText').remove();
    
    // Remove styling from the selected node
    $bodyCopy.find('div').each(function(){
        $(this).removeClass('selected');
    });
    
    // Reconstruct the new tree
    var $newHtml = $('<html></html>');
    $newHtml.append($newHead);
    $newHtml.append($bodyCopy);
    
    return $newHtml.html();
}
