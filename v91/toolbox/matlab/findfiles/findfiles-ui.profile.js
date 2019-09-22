// Copyright 2015 MathWorks, Inc.

var profile = {
    // The location of top level packages declared as dependencies in the UI
    // code. You'll see these in the AMD define() function. For example:
    // 		define(["dojo/store/Memory", "dijit/Dialog", "MW/Log"], function(...
    packages: [{
        name: "findfiles-ui",
        location: "findfiles-ui"
    }],

    // The JavaScript code will get minimized into layer files. dojo generates
    // files to: [releaseDir]/[package name]/[layer file name].
    layers: {
        "findfiles-ui/findfiles-ui": {
            copyright: "copyright.txt",
            include: [
                // Add your main application modules first
                "findfiles-ui/FindFilesUi"
            ],
            exclude: [
                "findfiles-ui/browsercheck"
            ]
        }
    }
};