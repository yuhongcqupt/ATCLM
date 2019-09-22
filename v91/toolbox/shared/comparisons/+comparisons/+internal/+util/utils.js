// Copyright 2016 The MathWorks, Inc.

// This disables use of the backspace control in the report, thereby preventing navigation to a 
// previous page using that key.
$(document).on("keydown", function (event) {
    if (event.which == 8 || event.keyCode == 8) {
        event.preventDefault();
    }
});
