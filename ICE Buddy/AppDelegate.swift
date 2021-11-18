//
//  AppDelegate.swift
//  ICE Buddy
//
//  Created by Frederik Riedel on 16.11.21.
//

import Cocoa
import FredKitAnalytics

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        FredKitAnalytics.setup(appId: "7")
        MenuBarController.shared.refreshMenuBarItem()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }


}

