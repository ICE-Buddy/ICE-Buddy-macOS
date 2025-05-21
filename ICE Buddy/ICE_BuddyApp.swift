//
//  ICE_BuddyApp.swift
//  ICE Buddy
//
//  Created by Simon Kroner on 19.05.25.
//

import SwiftUI
import UserNotifications

@main
struct ICE_BuddyApp: App {
    @StateObject var connectDataHandler = ConnectDataHandler()
    let notificationDelegate = NotificationDelegate()

    init() {
        let center = UNUserNotificationCenter.current()
        center.delegate = notificationDelegate
    }

    var body: some Scene {
        #if os(macOS)
            MenuBarExtra("ICE Buddy", image: "menu bar icon") {
                MenuBarView()
                    .environmentObject(connectDataHandler)
                    .frame(width: 350)
            }
            .menuBarExtraStyle(.window)

            Window("About", id: "aboutWindow") {
                AboutView()
                    .frame(width: 487, height: 345)
            }
            .windowResizability(.contentSize)
        #else
            WindowGroup {
                ContentView()
            }
        #endif
    }
}
