// The following JavaScript is a modified version of "SortTable", version 2
// by Stuart Langridge, http://www.kryogenix.org/code/browser/sorttable/
// Licenced as X11: http://www.kryogenix.org/code/browser/licence.html

sorttable = {
  init: function() {
        // quit if this function has already been called
        if (arguments.callee.done) return;
        // flag this function so we don't do the same thing twice
        arguments.callee.done = true;

        // kill the timer
        if (_timer) clearInterval(_timer);

        if (!document.createElement || !document.getElementsByTagName) return;

        sorttable.DATE_RE = /^(\d\d?)[\/\.-](\d\d?)[\/\.-]((\d\d)?\d\d)$/;

        // ICE Browser doesn't support the "forEach" functions in the original code.  Replace
        // with basic "for" loops
        var tables = document.getElementsByTagName('table');
        var index=0;
        for (index=0;index<tables.length;index=index+1) {
            if (tables.item(index).className.search(/\bsortable\b/) != -1) {
                sorttable.makeSortable(tables.item(index));
            }
        }
    },

    // For debugging on ICE, it's handy to uncomment the following two functions
    // and to call them to provide basic debugging.

    // Turns the text at the top of the table red.
    /*makeRed: function() {
        var element = document.getElementsByTagName('em');
        var index=0;
        for (index=0;index<element.length;index=index+1) {
            element.item(index).style.background='red';
        }
    },

    // Replaces the text at the top of the table with the supplied string 
    setString: function(str) {
        var element = document.getElementsByTagName('em');
        element[0].innerHTML = "Set: " + str;
    },*/

  makeSortable: function(table) {
        // Modified for difftool usage: use the last row of the table header
        // as the clickable column headers.
        var thead = table.getElementsByTagName('thead');
        var headrows = thead[0].getElementsByTagName('tr');
        var headrow = headrows[headrows.length-1].getElementsByTagName('th');

        for (var i=0; i<headrow.length; i++) {
            // manually override the type with a sorttable_type attribute
            if (!headrow[i].className.match(/\bsorttable_nosort\b/)) { // skip this col
                // Make any row which has a class name "sorttable_XXX" sortable.
                // To simplify the code for use on ICE Browser, we do not attempt
                // to guess the data type; it must be specified.
                mtch = headrow[i].className.match(/\bsorttable_([a-z0-9]+)\b/);
                if (mtch) {
                    // Assign the sorting function.
                    override = mtch[1];
                    headrow[i].sorttable_sortfunction = sorttable["sort_"+override];
                    headrow[i].sorttable_columnindex = i;
                    // On ICE we need the HTML to contain a explicit "tbody" tag, otherwise
                    // the following code doesn't work.
                    headrow[i].sorttable_tbody = table.getElementsByTagName('tbody')[0];
                    // Add a listener to sort the table when the header is clicked.
                    dean_addEvent(headrow[i],"click", tableSortFunction = function(e) {
                        // On ICE, the "th" element is the event's srcElement.
                        // On WebRenderer, it's "this".
                        if (navigator.appName=="ICEbrowser") {
                            headercell = e.srcElement;
                        } else {
                            headercell = this;
                        }

                        if (headercell.className.search(/\bsorttable_sorted\b/) != -1) {
                            // We're already sorted by this column, so just
                            // reverse the table (which is quicker than recalculating the order) 
                            sorttable.reverse(headercell.sorttable_tbody);
                            headercell.className = headercell.className.replace('sorttable_sorted',
                                                                    'sorttable_sorted_reverse');
                            headercell.removeChild(document.getElementById('sorttable_sortfwdind'));
                            sortrevind = document.createElement('span');
                            sortrevind.id = "sorttable_sortrevind";
                            sortrevind.innerHTML = '&nbsp;&#x25B4;'
                            headercell.appendChild(sortrevind);
                            return;
                        }
                        if (headercell.className.search(/\bsorttable_sorted_reverse\b/) != -1) {
                            // We're already sorted by this column, so just
                            // reverse the table (which is quicker than recalculating the order) 
                            sorttable.reverse(headercell.sorttable_tbody);
                            headercell.className = headercell.className.replace('sorttable_sorted_reverse',
                                                                    'sorttable_sorted');
                            headercell.removeChild(document.getElementById('sorttable_sortrevind'));
                            sortfwdind = document.createElement('span');
                            sortfwdind.id = "sorttable_sortfwdind";
                            sortfwdind.innerHTML = '&nbsp;&#x25BE;';
                            headercell.appendChild(sortfwdind);
                            return;
                        }

                        // remove sorttable_sorted classes from all columns
                        cells = headercell.parentNode.childNodes;
                        for (var index=0; index<cells.length; index++) {
                            if (cells[index].nodeType == 1) { // an element
                                cells[index].className = cells[index].className.replace('sorttable_sorted_reverse','');
                                cells[index].className = cells[index].className.replace('sorttable_sorted','');
                            }
                        }
                        sortfwdind = document.getElementById('sorttable_sortfwdind');
                        if (sortfwdind) { sortfwdind.parentNode.removeChild(sortfwdind); }
                        sortrevind = document.getElementById('sorttable_sortrevind');
                        if (sortrevind) { sortrevind.parentNode.removeChild(sortrevind); }

                        // Modify this column's class to indicate that it is sorted
                        headercell.className += ' sorttable_sorted';
                        sortfwdind = document.createElement('span');
                        sortfwdind.id = "sorttable_sortfwdind";
                        // Add the "sorted" marker to this column header
                        sortfwdind.innerHTML = '&nbsp;&#x25BE;';
                        headercell.appendChild(sortfwdind);

                        // build an array to sort. This is a Schwartzian transform thing,
                        // i.e., we "decorate" each row with the actual sort key,
                        // sort based on the sort keys, and then put the rows back in order
                        // which is a lot faster because you only do getInnerText once per row
                        row_array = [];
                        col = headercell.sorttable_columnindex;
                        // ICE Browser doesn't support tbody.rows, so search for the "tr"
                        // elements explicitly.
                        rows = headercell.sorttable_tbody.getElementsByTagName("tr");
                        for (var j=0; j<rows.length; j++) {
                            // Modified for difftool usage: cope with "colspan" attributes.
                            // Column "col" in the table, but due to "colspan" attributes on cells, not
                            // necessarily that index in the "cells" array.
                            var colcount = 0;
                            var rowcells = rows[j].getElementsByTagName("td"); // .cells no supported on ICE Browser
                            for (var q=0; q<=col; q++) {
                                thiscell = rowcells[q];
                                if (colcount==col) {
                                    // This is the column we need.
                                    row_array[j] = [sorttable.getInnerText(thiscell), j];
                                    break;
                                } else if (colcount>col) {
                                    // We've skipped the column we need.  Insert an empty entry.
                                    row_array[j] = ["", j]; // empty cell
                                    break;
                                }
                                if (thiscell.colSpan) {
                                    // Remind ICE Browser to treat the colSpan as a number.
                                    colcount = colcount + Number(thiscell.colSpan);
                                } else {
                                    colcount += 1;
                                }
                            }
                        }
                        row_array.sort(headercell.sorttable_sortfunction);

                        // Create a new array of rows.  (On ICE Browser just appending the
                        // rows without copying the array first seemed to confuse matters.) 
                        newrows = [];
                        for (var j=0; j<row_array.length; j++) {
                            newrows[j] = rows[row_array[j][1]];
                        }

                        // Copy the rows into the table body in their new order.
                        tb = headercell.sorttable_tbody;
                        for (var j=0; j<row_array.length; j++) {
                            tb.appendChild(newrows[j]);
                        }

                        delete row_array;
                    });
                }
            }
        }
    },

  getInnerText: function(node) {
        // gets the text we want to use for sorting for a cell.
        // strips leading and trailing whitespace.
        // this is *not* a generic getInnerText function; it's special to sorttable.
        // for example, you can override the cell text with a customkey attribute.
        // it also gets .value for <input> fields.

        hasInputs = (typeof node.getElementsByTagName == 'function') &&
        node.getElementsByTagName('input').length;

        if (node.getAttribute("sorttable_customkey") != null) {
            return node.getAttribute("sorttable_customkey");
        }
        else if (typeof node.textContent != 'undefined' && !hasInputs) {
            return node.textContent.replace(/^\s+|\s+$/g, '');
        }
        else if (typeof node.innerText != 'undefined' && !hasInputs) {
            return node.innerText.replace(/^\s+|\s+$/g, '');
        }
        else if (typeof node.text != 'undefined' && !hasInputs) {
            return node.text.replace(/^\s+|\s+$/g, '');
        }
        else {
            switch (node.nodeType) {
              case 3:
              if (node.nodeName.toLowerCase() == 'input') {
                  return node.value.replace(/^\s+|\s+$/g, '');
              }
              case 4:
              return node.nodeValue.replace(/^\s+|\s+$/g, '');
              break;
              case 1:
              case 11:
              var innerText = '';
              for (var i = 0; i < node.childNodes.length; i++) {
                  innerText += sorttable.getInnerText(node.childNodes[i]);
              }
              return innerText.replace(/^\s+|\s+$/g, '');
              break;
              default:
              return '';
            }
        }
    },

  reverse: function(tbody) {
        // reverse the rows in a tbody
        newrows = [];
        oldrows = tbody.getElementsByTagName("tr");
        for (var i=0; i<oldrows.length; i++) {
            newrows[newrows.length] = oldrows[i];
        }
        for (var i=newrows.length-1; i>=0; i--) {
            tbody.appendChild(newrows[i]);
        }
        delete newrows;
    },

  /* sort functions
     each sort function takes two parameters, a and b
     you are comparing a[0] and b[0] */
  // Modified for difftool usage: since the numbers we sort are sizes,
  // replace any non-numeric values with negative numbers, which puts them
  // at one end of the sorted list.  Use the numeric value of the first
  // character in the string to provide basic sorting here too.
  sort_numeric: function(a,b) {
        // ICE Browser throws an error if we end up trying to parse an invalid
        // string like just "-".  So remove dots and minus-signs just in case.
        aa = parseFloat(a[0].replace(/[^0-9]/g,''));
        if (isNaN(aa)) {
            if (a[0].length>0) {
                aa = -(a[0].charCodeAt(0));
            } else {
                // Empty string.  Use -1.
                aa = -1;
            }
        }
        bb = parseFloat(b[0].replace(/[^0-9]/g,''));
        if (isNaN(bb)) {
            if (b[0].length>0) {
                bb = -(b[0].charCodeAt(0));
            } else {
                // Empty string.  Use -1.
                bb = -1;
            }
        }
        return aa-bb;
    },
  // A renamed version of sort_numeric from the original version of this
  // file. This works with negative and fractional values, and is used by
  // the timezones function.
  sort_generalnumeric: function(a,b) {
        aa = parseFloat(a[0].replace(/[^0-9.-]/g,''));
        if (isNaN(aa)) aa = 0;
        bb = parseFloat(b[0].replace(/[^0-9.-]/g,''));
        if (isNaN(bb)) bb = 0;
        return aa-bb;
    },
  sort_alpha: function(a,b) {
        if (a[0]==b[0]) return 0;
        if (a[0]<b[0]) return -1;
        return 1;
    }
}

/* ******************************************************************
   Supporting functions: bundled here to avoid depending on a library
   ****************************************************************** */

// Dean Edwards/Matthias Miller/John Resig

/* for Mozilla/Opera9 */
    if (document.addEventListener) {
        document.addEventListener("DOMContentLoaded", sorttable.init, false);
    }

/*@if (@_win32)
  document.write("<script id=__ie_onload defer src=javascript:void(0)><\/script>");
  var script = document.getElementById("__ie_onload");
  script.onreadystatechange = function() {
  if (this.readyState == "complete") {
  sorttable.init(); // call the onload handler
  }
  };
  /*@end @*/

/* for Safari */
if (/WebKit/i.test(navigator.userAgent)) { // sniff
    var _timer = setInterval(function() {
            if (/loaded|complete/.test(document.readyState)) {
                sorttable.init(); // call the onload handler
            }
        }, 10);
}

/* for other browsers */
window.onload = sorttable.init;

// written by Dean Edwards, 2005
// with input from Tino Zijdel, Matthias Miller, Diego Perini

// http://dean.edwards.name/weblog/2005/10/add-event/

function dean_addEvent(element, type, handler) {
    if (element.addEventListener) {
        element.addEventListener(type, handler, false);
    } else {
        // assign each event handler a unique ID
        if (!handler.$$guid) handler.$$guid = dean_addEvent.guid++;
        // create a hash table of event types for the element
        if (!element.events) element.events = {};
        // create a hash table of event handlers for each element/event pair
        var handlers = element.events[type];
        if (!handlers) {
            handlers = element.events[type] = {};
            // store the existing event handler (if there is one)
            if (element["on" + type]) {
                handlers[0] = element["on" + type];
            }
        }
        // store the event handler in the hash table
        handlers[handler.$$guid] = handler;
        // assign a global event handler to do all the work
        element["on" + type] = handleEvent;
    }
};
// a counter used to create unique IDs
dean_addEvent.guid = 1;

function removeEvent(element, type, handler) {
    if (element.removeEventListener) {
        element.removeEventListener(type, handler, false);
    } else {
        // delete the event handler from the hash table
        if (element.events && element.events[type]) {
            delete element.events[type][handler.$$guid];
        }
    }
};

function handleEvent(event) {
    var returnValue = true;
    // grab the event object (IE uses a global event object)
    event = event || fixEvent(((this.ownerDocument || this.document || this).parentWindow || window).event);
    // get a reference to the hash table of event handlers
    var handlers = this.events[event.type];
    // execute each event handler
    for (var i in handlers) {
        this.$$handleEvent = handlers[i];
        if (this.$$handleEvent(event) === false) {
            returnValue = false;
        }
    }
    return returnValue;
};

function fixEvent(event) {
    // add W3C standard event methods
    event.preventDefault = fixEvent.preventDefault;
    event.stopPropagation = fixEvent.stopPropagation;
    return event;
};
fixEvent.preventDefault = function() {
    this.returnValue = false;
};
fixEvent.stopPropagation = function() {
    this.cancelBubble = true;
}

