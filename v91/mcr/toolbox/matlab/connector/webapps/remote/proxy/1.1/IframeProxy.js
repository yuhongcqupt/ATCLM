/*global window,document,XMLHttpRequest,addEventListener */

(function () {
    var childIframes = [];
    var inFlightTransactions = {};
    var noop = function () {};

    function postMessage(action, message) {
        // todo: find a way to make this more secure (get rid of the "*")
        //test code modification
        parent.postMessage(action + ";" + message || "", "*");
    }

    function handleXhrResponse(id, response) {
        var message = id + ";success;" + response;
        postMessage("sendMessageResponse", message);
    }

    function handleXhrFault(id, fault, status) {
        var message = id + ";fault;" + fault + ";" + status;
        postMessage("sendMessageResponse", message);
    }

    // Handle the message event for this iframe. They could come from the parent or the child
    // windows.
    function handleMessage(event) {
        var idIndex, endpointIndex, id, endpoint, messageData, iframe, i, optionsIndex, options;
        var xhr, complete, header;

        if (event.source === parent) {
            // event.data format:
            // <action>;<data>
            // Handled actions:
            // sendMessage;<id>;<endpoint>;<request JSON>
            // createUploadIframe;<id>
            var actionIndex = event.data.indexOf(";");

            var action = event.data.substring(0, actionIndex);

            if (!action) {
                throw new Error("Unable to parse message, no action specified: " + event.data);
            }

            switch (action) {

            // send a message on behalf of the client
            case "sendMessage":
                idIndex = event.data.indexOf(";", actionIndex + 1);
                endpointIndex = event.data.indexOf(";", idIndex + 1);
                optionsIndex = event.data.indexOf(";", endpointIndex + 1);

                id = event.data.substring(actionIndex + 1, idIndex);
                endpoint = event.data.substring(idIndex + 1, endpointIndex);
                options = JSON.parse(event.data.substring(endpointIndex + 1, optionsIndex));
                messageData = event.data.substring(optionsIndex + 1, event.data.length);

                if (id && endpoint && messageData) {
                    try {
                        xhr = new XMLHttpRequest();
                        inFlightTransactions[id] = {xhr: xhr};

                        complete = false;
                        xhr.onreadystatechange = function () {
                            var status;
                            if (xhr.readyState === 0) {
                                // 0 means cancelled
                                complete = true;
                                handleXhrFault(id, "XHR readyState 0");
                            } else if (xhr.readyState === 4 && !complete) {
                                // 4 is done
                                complete = true;

                                status = xhr.status || 0;
                                if ((status >= 200 && status < 300) || status === 304) {
                                    handleXhrResponse(id, xhr.responseText);
                                } else {
                                    handleXhrFault(id, xhr.responseText, status);
                                }
                            }
                            if (complete && xhr) {
                                // memory leak prevention
                                xhr.onreadystatechange = noop;
                                xhr = null;
                                delete inFlightTransactions[id].xhr;
                                delete inFlightTransactions[id];
                            }
                        };

                        xhr.open("POST", endpoint, true);

                        xhr.setRequestHeader("Content-Type", options.contentType ?
                                options.contentType : "application/json");
                        xhr.setRequestHeader("X-Requested-With", "XMLHttpRequest");

                        if (options.headers) {
                            for (header in options.headers) {
                                if (options.headers.hasOwnProperty(header)) {
                                    xhr.setRequestHeader(header, options.headers[header]);
                                }
                            }
                        }

                        xhr.send(messageData);
                    } catch (e) {
                        handleXhrFault(id, "Unable to send data: " + e.toString());
                    }
                } else {
                    throw new Error("Invalid message to send: " + event.data);
                }
                break;

            // create an iframe which can be POSTed to from the client window to safely upload
            case "createUploadIframe":
                id = event.data.substring(actionIndex + 1, event.data.length);
                if (!document.getElementById(id)) {
                    iframe = document.createElement("iframe");
                    iframe.id = id;
                    iframe.name = id;
                    iframe.src = "about:blank";
                    iframe.width = 0;
                    iframe.height = 0;
                    iframe.style = "visibility: hidden; display: none;";
                    childIframes.push(iframe);
                    document.body.appendChild(iframe);
                }
                break;

            case "cancelUpload":
                id = event.data.substring(actionIndex + 1, event.data.length);
                var uploadIframe = document.getElementById(id);
                if (uploadIframe) {
                    if (navigator.appVersion.indexOf("MSIE") !== -1) {
                        uploadIframe.contentWindow.document.execCommand("Stop");
                    } else {
                        uploadIframe.contentWindow.stop();
                    }
                }
                break;

            // abort an in progress XHR
            case "abort":
                id = event.data.substring(actionIndex + 1, event.data.length);
                if (inFlightTransactions[id]) {
                    inFlightTransactions[id].xhr.abort();
                }
                break;

            default:
                throw new Error("Unknown action: " + action);
            }
        } else {
            for (i = 0; i < childIframes.length; i += 1) {
                if (event.source === childIframes[i].contentWindow) {
                    postMessage("uploadIframeMessage", childIframes[i].id + ";" + event.data);
                }
            }
        }
    }

    addEventListener("message", handleMessage);

    postMessage("ready", "");

    if (window.console) {
        console.log("iframe " + location + " ready at " + new Date());
    }
}());
