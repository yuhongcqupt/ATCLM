// Copyright 2015 MathWorks, Inc.
define([
    "dojo/_base/declare",
    "dojo/_base/lang",
    "MW/remote/MessageService"
], function (declare, lang, MessageService) {

    var PUBLISH_CHANNEL = "/matlab/findFiles/fromJs";
    var SUBSCRIBE_CHANNEL = "/matlab/findFiles/fromJava";

    return declare([], {

        _messageType: "",
        _callbackFunction:"",

        constructor: function (args) {
            MessageService.start();
            if (args) {
                this.subscribe(lang.hitch(this,this._handleResponse));
                this._messageType = args.messageType;
                this._callbackFunction = args.callback;
            }
        },

        publish: function (message) {
            MessageService.publish(PUBLISH_CHANNEL, message);
        },

        subscribe: function (callback) {
            MessageService.subscribe(SUBSCRIBE_CHANNEL, callback);
        },

        _handleResponse: function(message){
            var data = message.data;
            if(this._messageType === data.type ){
                this._callbackFunction(data);
            }
        }
    });
});