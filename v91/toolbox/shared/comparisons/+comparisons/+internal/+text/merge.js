// Copyright 2013-2015 The MathWorks, Inc.

var getTextWorkaroundPrefix = "BEGIN_PRE_TAG_IE_WORKAROUND";
var getTextWorkaroundSuffix = "END_PRE_TAG_IE_WORKAROUND";
var UNDO_STACK = new Array;
var REDO_STACK = new Array;

function createMergeState(node, previousRightText) {

    var clone = node.cloneNode(true);
    $(clone).removeClass('selected');
    
    return {
        nodeToRestore: clone,
        rightText: previousRightText,
        numLinesToIncrement: 0
    };
}

function merge(idOfDiffToMerge) {
    var diffNode;
    if (idOfDiffToMerge) {
        diffNode = document.getElementById(idOfDiffToMerge);
    } else {
        // If no id is provided then use the currently selected diff
        diffNode = CURRENT_SECTION;
    }
    
    if (diffNode != null) {
        var leftText = getFileNodeTextById('leftText');
        var leftLines = leftText.split('\n');
        var rightText = getFileNodeTextById('rightText');
        var rightLines = rightText.split('\n');

        var mergeState = createMergeState(diffNode, rightText);
        UNDO_STACK.push(mergeState);

        var diffLines = getElementsByClassName(diffNode, 'diffLine');

        var rightLineShift = 0;
        var indexOfCurrentLine = 0;
        var numLinesToMerge = diffLines.length;


        var mergeLine = function() {
            var diffLine = diffLines[indexOfCurrentLine];
            var leftLineNum = parseInt(diffLine.getAttribute('data-left-line'));
            var rightLineNum = parseInt(diffLine.getAttribute('data-right-line'));

            var leftLineText = leftLines[leftLineNum-1];

            // This is necessary because of browser differences.  IE returns
            // the string with the newline character while other browsers don't
            leftLineText = _stripNewLineCharacterFromEndOfText(leftLineText);
            
            var match = getElementsByClassName(diffLine, 'diffnomatch');
            if (match.length != 0) {
                rightLines[rightLineNum - 1] = leftLineText;
                _mergeLine(diffLine, leftLineText);
            } else {
                var oldSpan = getElementsByClassName(diffLine, 'diffold');
                var newSpan = getElementsByClassName(diffLine, 'diffnew');

                // Perform a deletion
                if (getNodeIndex(oldSpan[0]) < getNodeIndex(newSpan[0])) {
                    var lineNumToRemove = rightLineNum - 1;
                    rightLines.splice(lineNumToRemove,1);
                    rightLineShift -= 1;
                    _deleteLine(diffLine, lineNumToRemove);
                }

                // Perform insertion
                if (getNodeIndex(oldSpan[0]) > getNodeIndex(newSpan[0])) {
                    var insertionLineNum = rightLineNum;
                    rightLines.splice(insertionLineNum, 0, leftLineText);
                    rightLineShift += 1;
                    _insertLine(diffLine, leftLineText, insertionLineNum + 1);
                }
            }

            indexOfCurrentLine += 1;
            if (indexOfCurrentLine == numLinesToMerge) {
                completeMergeAction();
            } else {
                setTimeout(mergeLine, 20);
            }
        }

        var completeMergeAction = function() {
            var rightTextNode = document.getElementById('rightText');
            setPreformattedNodeText(rightTextNode, rightLines.join('\n'));
            mergeState.numLinesToIncrement = rightLineShift;
            $(diffNode).addClass('mergedDiff');
            _addDirtyFlagToFileHyperlink('rightFileLink');
            _fireMergeActionFinished();
        }

        // Start the merge process
        mergeLine();
    }
}

function undo() {
    var state = UNDO_STACK.pop();
    if (!state) {
        return;
    }
    
    var diffNodeToRestore = state.nodeToRestore;
    var idOfNodeToRestore = diffNodeToRestore.getAttribute('id');
    var currentDiffNode = document.getElementById(idOfNodeToRestore);

    if (Math.abs(state.numLinesToIncrement) > 0) {
        var diffs = getElementsByClassName(currentDiffNode, 'nodiff');
        var rightLineNum = parseInt(diffs[diffs.length-1].getAttribute('data-right-line'));
        _changeRightFileLineNumbersAll(rightLineNum + 1, -state.numLinesToIncrement);
    }

    var parent = currentDiffNode.parentNode;
    parent.replaceChild(diffNodeToRestore, currentDiffNode);

    if (CURRENT_SECTION && CURRENT_SECTION.id === idOfNodeToRestore) {
        setcurrent(diffNodeToRestore, false);
    }

    setPreformattedNodeText(document.getElementById('rightText'), state.rightText);

    if (UNDO_STACK.length == 0) {
        _removeDirtyFlagFromFileHyperlink('rightFileLink');
    }
    
    REDO_STACK.push(state);
    _fireMergeActionFinished();
}

function redo() {
    var state = REDO_STACK.pop();
    if (!state) {
        return;
    }
    merge(state.nodeToRestore.id);
}

function clearRedoStack() {
    REDO_STACK.length = 0;
}

function _stripNewLineCharacterFromEndOfText(text) {
    if (text) {
        return text.replace(/(\r\n|\r|\n)$/,"");
    }
    return text;
}

function _fireMergeActionFinished() {
    var rootWindow = getRootWindow();
    var selectedDiffMerged = _isSelectedDiffMerged();
    rootWindow.location = "merge:" + UNDO_STACK.length + '@' + REDO_STACK.length + '#' + NUM_DIFFS + '$' + selectedDiffMerged;
}

function _isSelectedDiffMerged() {
    if (!CURRENT_SECTION) {
        return false;
    }
    var classes = CURRENT_SECTION.className;
    if (classes && (classes.search('merged') >= 0)) {
        return true;
    }
    return false;
}

function _mergeLine(diffLine, newText) {
    _markLineIdentical(diffLine);
    var mergedNode = _createMergedSpanNodeWithText(newText);
    var childDiffNode = getElementsByClassName(diffLine, 'diffnomatch')[0];
    diffLine.replaceChild(mergedNode, childDiffNode);
    _applyMergedIcon(diffLine);
    diffLine.setAttribute('data-merged', 'true');
}

function _insertLine(diffLine, newText, newLineNum) {
    _markLineIdentical(diffLine);
    var mergedNode = _createMergedSpanNodeWithText(newText);
    
    var childLeftContentsNode = getElementsByClassName(diffLine, 'diffnew')[0];
    diffLine.replaceChild(mergedNode, childLeftContentsNode);
    
    var childRightContentsNode = getElementsByClassName(diffLine, 'diffold')[0];
    diffLine.removeChild(childRightContentsNode);
    
    _incrementRightFileLineNumbers(diffLine, newLineNum - 1);
    _changeRightNodeLineNumbers(diffLine, newLineNum);
    
    var hasHyperlink = diffLine.getElementsByTagName('a').length != 0;
    if (hasHyperlink) {
        var lineNumNode = _createOpenRightHyperlinkNode(newLineNum);
    } else {
        var lineNumNode = _createNoLinkLineNumNode(newLineNum);
    }
    var childNoLineNumNode = getElementsByClassName(diffLine, 'diffsoft')[0];
    diffLine.replaceChild(lineNumNode, childNoLineNumNode);

    _applyMergedIcon(diffLine);
    diffLine.setAttribute('data-inserted', 'true');
}

function _deleteLine(diffLine, lineNum) {
    _markLineIdentical(diffLine);
    
    _decrementRightFileLineNumbers(lineNum + 1);
    _changeRightNodeLineNumbers(diffLine, lineNum);
    
    var emptyLineNumNode = _createEmptyLineNum();
    var childLineNumNode = diffLine.lastChild;
    diffLine.replaceChild(emptyLineNumNode, childLineNumNode);
    
    var childLeftContentsNode = getElementsByClassName(diffLine, 'diffold')[0];
    var leftChildText = getNodeText(childLeftContentsNode);
    diffLine.removeChild(childLeftContentsNode);
    
    var childRightContentsNode = getElementsByClassName(diffLine, 'diffnew')[0];
    var rightChildText = getNodeText(childRightContentsNode);
    
    var newText = leftChildText.concat(rightChildText);
    var spanNode = document.createElement('span');
    spanNode.className = 'merged';
    
    var textNode = document.createTextNode(newText);
    spanNode.appendChild(textNode);
    
    diffLine.replaceChild(spanNode, childRightContentsNode);
    _applyDeletedIcon(diffLine);
    diffLine.setAttribute('data-deleted', 'true');
}

function _markLineIdentical(line) {
    line.className = 'nodiff';
}

function _createMergedSpanNodeWithText(text) {
    var spanNode = document.createElement('span');
    spanNode.className = 'merged';
    spanNode.appendChild(_createIdenticalTextNode(text));
    return spanNode;
}

function _createIdenticalTextNode(text) {
    var fullLineText = _widthAdjustText(text) + " . " + _widthAdjustText(text);
    return document.createTextNode(fullLineText);
}

function _widthAdjustText(text) {
    var text = _replaceTabsWithSpaces(text);
    if (text.length > WIDTH) {
        return text.slice(0, WIDTH);
    } else {
        var numToAdd = WIDTH - text.length;
        return text.concat(_createWhiteSpaceArray(numToAdd));
    }
}

function _replaceTabsWithSpaces(text) {
    var offsetFromPreviousReplaceOperations = 0;
    return text.replace(/\t/g, function(matchedString, indexOfTabInOriginalString) {
        var indexOfCharacterAfterTab = indexOfTabInOriginalString + offsetFromPreviousReplaceOperations + 1;
        var numCharactersUntilNextTabLocation = indexOfCharacterAfterTab%NUM_SPACES_PER_TAB;
        // + 1 as a replacement for the tab character
        var numSpacesToAdd = NUM_SPACES_PER_TAB - numCharactersUntilNextTabLocation + 1;
        if (numSpacesToAdd !== 0) {
            // Increment by number of spaces - 1 for the tab character
            offsetFromPreviousReplaceOperations += numSpacesToAdd - 1;
        }
        return _createWhiteSpaceArray(numSpacesToAdd);
    });
}

function _createWhiteSpaceArray(size) {
    // The join operation places the specified character between each element
    // of the array.  The starting array must be of size + 1 for the resulting 
    // array to have the correct length.
    return Array(size + 1).join(" ");
}

function _createEmptyLineNum() {
    var emptyNode = document.createElement("span");
    emptyNode.className = 'diffsoft';
    setNodeText(emptyNode, '  -');
    return emptyNode;
}

function _createOpenRightHyperlinkNode(lineNum) {
    var hyperlinkNode = _createLineNumNode(lineNum, 'a');
    hyperlinkNode.setAttribute('href', 'javascript:openright(' + lineNum + ');');
    return hyperlinkNode;
}

function _createNoLinkLineNumNode(lineNum) {
    return _createLineNumNode(lineNum, 'span');
}

function _createLineNumNode(lineNum, tagName) {
    var node = document.createElement(tagName);
    var text = lineNum.toString();
    if (text.length < 3) {
        text = _createWhiteSpaceArray(3 - text.length) + text;
    }
    setNodeText(node, text);
    return node;
}

function _decrementRightFileLineNumbers(lineNum) {
    _changeRightFileLineNumbersAll(lineNum, -1);
}

function _incrementRightFileLineNumbers(fromNode, lineNum) {
    var spanNodes = document.getElementsByTagName('span');
    var nodeArray = [].slice.call(spanNodes);
    var nodesToIncrement = nodeArray.slice(nodeArray.indexOf(fromNode), nodeArray.length);
    _changeRightFileLineNumbers(nodesToIncrement, lineNum, 1);
}

function _changeRightFileLineNumbersAll(lineNum, direction) {
    var spanNodes = document.getElementsByTagName('span');
    var nodeArray = [].slice.call(spanNodes);
    _changeRightFileLineNumbers(nodeArray, lineNum, direction);
}

function _changeRightFileLineNumbers(spanNodes, lineNum, direction) {
    spanNodes.forEach(function(spanNode) {
        var attributeName = 'data-right-line';
        if (spanNode.getAttribute(attributeName)) {
            var num = parseInt(spanNode.getAttribute(attributeName));
            if (num >= lineNum) {
                _changeRightNodeLineNumbers(spanNode, num += direction);
            }
        }
    });
}

function _changeRightNodeLineNumbers(node, num) {
    node.setAttribute('data-right-line', num);
    _changeRightVisibleLineNumber(node, num);
}

function _changeRightVisibleLineNumber(node, num) {
    var lineNumNode = node.lastChild;
    if (!parseInt(getNodeText(lineNumNode))) {
        return;
    }
    
    var hasHyperlink = node.getElementsByTagName('a').length != 0;
    if (hasHyperlink) {
        var newLineNumNode = _createOpenRightHyperlinkNode(num);
    } else {
        var newLineNumNode = _createNoLinkLineNumNode(num);
    }
    var parent = lineNumNode.parentNode;
    parent.replaceChild(newLineNumNode, lineNumNode);
}

function getNodeIndex(node) {
    var i = 0;
    while((node = node.previousSibling) != null) {
        i++;
    }
    return i;
}

function getElementsByClassName(nodeToSearchFrom, className) {
    var elements = [];
    $(nodeToSearchFrom).find('.' + className).each(function(){
        elements.push(this);
    });
    return elements;
}

function getNodeText(node) {
    if (node.textContent != undefined) {
        text = node.textContent;
    } else {
        text = node.innerText;
    }
    
    return _normalizeLineEndings(text);
}

function _normalizeLineEndings(text) {
    if (text) {
        text = text.replace(/(\r\n|\n|\r)/g,'\n');
    }
    return text;
}

function getNodeTextById(id) {
    var node = document.getElementById(id);
    if (!node) {
        return null;
    }
    return getNodeText(node);
}

function getFileNodeTextById(id) {
    var text = getNodeTextById(id);
    return text.substring(getTextWorkaroundPrefix.length, text.length - getTextWorkaroundSuffix.length);
}

function setNodeText(node, text) {
    if (node.textContent != undefined) {
        node.textContent = text;
    } else {
        node.innerText = text;
    }
}

function setPreformattedNodeText(node, text) {
    $(node).html('');
    var preTag = document.createElement('pre');
    var textNode = document.createTextNode(wrapPreformattedNodeText(text));
    preTag.appendChild(textNode);
    node.appendChild(preTag);
}

function wrapPreformattedNodeText(text) {
    return getTextWorkaroundPrefix + text + getTextWorkaroundSuffix;
}

var originalSetCurrentFunction = setcurrent;
setcurrent = function(section, scroll) {
    originalSetCurrentFunction(section, scroll);
    fireSelectionChanged();
}

function fireSelectionChanged() {
    var rootWindow = getRootWindow();
    var message = "selection:";
    if (CURRENT_SECTION == null) {
        message = message + "null";
    } else {
        message = message + CURRENT_SECTION.id;
        var classes = CURRENT_SECTION.className;
        if (classes && (classes.search('merged') >= 0)) {
            message += "@merged"
        }
    }
    rootWindow.location = message;
}

function _applyMergedIcon(node) {
    if (node) {
        var spanNode = document.createElement('span');
        spanNode.className = 'icon overwrite';
        node.appendChild(spanNode);
    }
}

function _applyDeletedIcon(node) {
    if (node) {
        var spanNode = document.createElement('span');
        spanNode.className = 'icon delete';
        node.appendChild(spanNode);
    }
}

function _addDirtyFlagToFileHyperlink(linkId) {
    var fileLink = document.getElementById(linkId);
    if (!fileLink) {
        return;
    }
    
    var text = getNodeText(fileLink);
    if (text.indexOf('*') < 0) {
        setNodeText(fileLink, text + "*");
    }
}

function _removeDirtyFlagFromFileHyperlink(linkId) {
    var fileLink = document.getElementById(linkId);
    if (!fileLink) {
        return;
    }
    
    var text = getNodeText(fileLink);
    if (text) {
        setNodeText(fileLink, text.replace('*',''));
    }
}
