// Copyright 2015 MathWorks, Inc.
require(["dojo/on",
        "dojo/dom",
        "dojo/dom-style",
        "dojo/dom-construct",
        "dojo/_base/lang",
        "dojo/_base/declare",
        "dojo/store/Memory",
        "findfiles-ui/js/MessageServiceHelperForFindFiles",
        "findfiles-ui/js/MessageType",
        "dijit/registry",
        "dijit/form/Form",
        "dgrid/OnDemandGrid",
        "dgrid/extensions/ColumnResizer",
        "dgrid/Keyboard",
        "dgrid/Selection",
        "MW/form/ComboBox",
        "MW/form/CheckBox",
        "MW/form/PushButton",
        "dojo/domReady!"],
    function (on, dom, domStyle, domConstruct, lang, declare, Memory, MSHelper, msgType, registry, Form, OnDemandGrid, ColumnResizer, Keyboard, Selection, ComboBox, CheckBox, PushButton) {

        // Find files named combobox
        new ComboBox({
            id: "filesNamedComboBox",
            items: [],
            value: "TEMP",
            width: 419,
            editable: true
        }, "filesNamed").startup();

        // Find files containing text combobox
        new ComboBox({
            id: "filesContainingTextComboBox",
            items: [],
            value: "TEMP",
            width: 419,
            editable: true
        }, "filesContainingText").startup();

        // Match case checkbox
        new CheckBox({
            id: "matchCaseCheckBox",
            text: "Match case",
            checked: false
        }, "matchCase").startup();

        // Match whole word checkbox
        new CheckBox({
            id: "matchWholeWordCheckBox",
            text: "Matches whole word",
            checked: false
        }, "matchWholeWord").startup();

        // Include only file type(s) select
        var includeFileTypesComboBoxItems = [];
        [   "All files (*)",
            "*.mlappinstall, *.mlx, *.fig, *.mat, *.m, *.slx, *.sldd, *.sltx, *.mltbx, *.mldatx, *.req, *.prj, *.mdl",
            "*.m, *.mlx",
            "*.mat",
            "*.txt"
        ].forEach(function (fileTypeString) {
            includeFileTypesComboBoxItems.push({value: fileTypeString, label: fileTypeString});
        });
        new ComboBox({
            id: "includeFileTypesComboBox",
            items: includeFileTypesComboBoxItems,
            width: 419,
            value: includeFileTypesComboBoxItems[0].value
        }, "includeFileTypes").startup();

        // Look in combobox
        var lookInComboBoxItems = [];
        [   "Current folder",
            "Entire MATLAB path",
            "Browse..."
        ].forEach(function (locationString) {
            lookInComboBoxItems.push({value: locationString, label: locationString});
        });
        new ComboBox({
            id: "lookInComboBox",
            items: lookInComboBoxItems,
            width: 419,
            value: lookInComboBoxItems[0].value,
            editable: true
        }, "lookIn").startup();

        // Include subfolders checkbox
        new CheckBox({
            id: "includeSubfoldersCheckBox",
            text: "Include subfolders",
            checked: false
        }, "includeSubfolders").startup();

        // Find button
        new PushButton({
            id: "findButton",
            text: "Find"
        }, "findButton").startup();

        // Results panel
        var searchResultsPanel = new (declare([OnDemandGrid, ColumnResizer, Keyboard, Selection]))({
            columns: {
                fileName: "File Name",
                line: "Line",
                text: "Text"
            },
            selectionMode: "single",
            cellNavigation: false
        }, "searchResultsPanel");

        // Show full path names checkbox
        new CheckBox({
            id: "showFullPathNamesCheckBox",
            text: "Show full path names",
            checked: false
        }, "showFullPathNames").startup();

        // Close button
        new PushButton({
            id: "closeButton",
            text: "Close"
        }, "closeButton").startup();

        // Help button
        new PushButton({
            id: "helpButton",
            text: "Help"
        }, "helpButton").startup();

        var editorOptionsIncluded = false;
        var msHelper = new MSHelper();
        var intervalUpdateResults = null;
        var fileNameStore, fullPathNameStore;
        var searchResultsLabel = dom.byId("searchResultsLabel"),
            messageDisplay = dom.byId("messageDisplay"),
            findButton = registry.byId("findButton"),
            closeButton = registry.byId("closeButton"),
            helpButton = registry.byId("helpButton"),
            filesNamedComboBox = registry.byId("filesNamedComboBox"),
            filesContainingTextComboBox = registry.byId("filesContainingTextComboBox"),
            matchCaseCheckBox = registry.byId("matchCaseCheckBox"),
            matchWholeWordCheckBox = registry.byId("matchWholeWordCheckBox"),
            includeFileTypesComboBox = registry.byId("includeFileTypesComboBox"),
            lookInComboBox = registry.byId("lookInComboBox"),
            includeSubfoldersCheckBox = registry.byId("includeSubfoldersCheckBox"),
            showFullPathNamesCheckBox = registry.byId("showFullPathNamesCheckBox");

        function arrayContainsObject (array, object) {
            for (var i = 0; i < array.length; i++) {
                if (array[i].value === object.value && array[i].label === object.label) {
                    return true;
                }
            }
            return false;
        }

        function addMenuItemsToMwComboBox (widget, items, index) { // Todo: g1281033
            var existingItems = widget.get("items");
            var comboBoxChanged = false;
            for (var i = items.length-1; i >= 0; i--) {
                var newMenuItem = items[i];
                if (!arrayContainsObject(existingItems, newMenuItem)) {
                    comboBoxChanged = true;
                    if (index) {
                        existingItems.splice(index, 0, newMenuItem);
                    } else {
                        existingItems.push(newMenuItem);
                    }
                }
            }
            if (comboBoxChanged) {
                widget.get("menu").destroyDescendants();
                widget._initMenuItems(existingItems);
            }
        }

        function addToComboBox (widget, text) {
            if (text) {
                addMenuItemsToMwComboBox(widget, [{value: text, label: text}]);
                widget.set("value", text);
            }
        }

        // Publish messages to start or stop searches
        on(findButton, "click", function (e) {
            if (findButton.get("text") == "Find") {
                var fileName = filesNamedComboBox.get("_textField").get("value"),
                    fileText = filesContainingTextComboBox.get("_textField").get("value"),
                    matchCase = matchCaseCheckBox.get("checked"),
                    matchWholeWord = matchWholeWordCheckBox.get("checked"),
                    includeFileTypesEnabled = !(fileName.indexOf(".") > -1),
                    includeFileTypes = includeFileTypesComboBox.get("value"),
                    lookIn = lookInComboBox.get("value"),
                    includeSubfolders = includeSubfoldersCheckBox.get("checked");
                addToComboBox(filesNamedComboBox, fileName);
                addToComboBox(filesContainingTextComboBox, fileText);
                msHelper.publish({
                    action: msgType.FIND,
                    fileName: fileName,
                    fileText: fileText,
                    matchCase: matchCase,
                    matchWholeWord: matchWholeWord,
                    includeFileTypesEnabled: includeFileTypesEnabled,
                    includeFileTypes: includeFileTypes,
                    lookIn: lookIn,
                    includeSubfolders: includeSubfolders
                });
            } else if (findButton.get("text") == "Stop"){
                msHelper.publish({action: msgType.STOP});
            }
        });

        // Publish message to stop search and close CEF
        on(closeButton, "click", function (e) {
            msHelper.publish({action: msgType.STOP});
            msHelper.publish({action: msgType.CLOSE});
        });

        // Publish message to launch help window
        on(helpButton, "click", function (e) {
            msHelper.publish({action: msgType.HELP});
        });

        // Update search results for full path name
        showFullPathNamesCheckBox.on("change", function(e) {
            if (e.mwEventData.newValue) {
                searchResultsPanel.set("store", fullPathNameStore);
            } else {
                searchResultsPanel.set("store", fileNameStore);
            }
        });

        function showError (data) {
            alert(data.errorMessage);
        }

        function beginFind () {
            findButton.set("text", "Stop");
            searchResultsLabel.innerHTML = "";
            fileNameStore = new Memory({data: []});
            fullPathNameStore = new Memory({data: []});
            searchResultsPanel.set("store",
                (showFullPathNamesCheckBox.get("checked")) ? fullPathNameStore: fileNameStore);
            intervalUpdateResults = setInterval(function(){
                searchResultsPanel.refresh({keepScrollPosition: true});
            }, 100);
        }

        function addToResultsTable (data) {
            fileNameStore.add({
                fileName: data.searchResultFileName,
                line: data.searchResultLine,
                text: data.searchResultText
            });
            fullPathNameStore.add({
                fileName: data.searchResultFullPath,
                line: data.searchResultLine,
                text: data.searchResultText
            });
        }

        function setSearchLabel (data) {
            searchResultsLabel.innerHTML = data.searchLabelText;
        }

        function setResultsLabel (data) {
            searchResultsLabel.innerHTML = data.resultsLabelText;
        }

        function finishFind () {
            clearInterval(intervalUpdateResults);
            searchResultsPanel.refresh({keepScrollPosition: true});
        }

        function setMouseCursorToDefault () {
            // Todo
        }

        function replaceStopButtonWithFindButton () {
            findButton.set("text", "Find");
        }

        function addToLookInComboBox (data) {
            // Todo
        }

        function updateLookInEditorOptions (data) { // Todo: g1281033
            if (data.includeEditorOptions && !editorOptionsIncluded) {
                addMenuItemsToMwComboBox (lookInComboBox, [
                    {value: "Editor - Current file's folder", label: "Editor - Current file's folder"},
                    {value: "Editor - All open files", label: "Editor - All open files"}
                ], 1);
                editorOptionsIncluded = true;
            } else if (editorOptionsIncluded) {
                var existingItems = lookInComboBox.get("items");
                existingItems.splice(1, 2);
                lookInComboBox.get("menu").destroyDescendants();
                lookInComboBox._initMenuItems(existingItems);
                lookInComboBox.set("value", lookInComboBoxItems[0].value);
                editorOptionsIncluded = false;
            }
        }

        // Update UI in response to messages from controller
        new MSHelper({messageType: msgType.SHOW_ERROR,
            callback: lang.hitch(this, showError)});
        new MSHelper({messageType: msgType.BEGIN_FIND,
            callback: lang.hitch(this, beginFind)});
        new MSHelper({messageType: msgType.ADD_TO_RESULTS_TABLE,
            callback: lang.hitch(this, addToResultsTable)});
        new MSHelper({messageType: msgType.SET_SEARCH_LABEL,
            callback: lang.hitch(this, setSearchLabel)});
        new MSHelper({messageType: msgType.SET_RESULTS_LABEL,
            callback: lang.hitch(this, setResultsLabel)});
        new MSHelper({messageType: msgType.FINISH_FIND,
            callback: lang.hitch(this, finishFind)});
        new MSHelper({messageType: msgType.SET_MOUSE_CURSOR_TO_DEFAULT,
            callback: lang.hitch(this, setMouseCursorToDefault)});
        new MSHelper({messageType: msgType.REPLACE_STOP_BUTTON_WITH_FIND_BUTTON,
            callback: lang.hitch(this, replaceStopButtonWithFindButton)});
        new MSHelper({messageType: msgType.ADD_TO_LOOK_IN_COMBO_BOX,
            callback: lang.hitch(this, addToLookInComboBox)});
        new MSHelper({messageType: msgType.UPDATE_LOOK_IN_EDITOR_OPTIONS,
            callback: lang.hitch(this, updateLookInEditorOptions)});

        // Finished loading
        domStyle.set(dom.byId("loadingMask"), "display", "none");
        msHelper.publish({action: msgType.JS_LOADED});
    });
