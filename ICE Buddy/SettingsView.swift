//
//  SettingsView.swift
//  ICE Buddy
//
//  Created by Simon Kroner on 21.05.25.
//

import LaunchAtLogin
import SwiftUI

struct SettingsView: View {
    @Environment(\.openWindow) private var openWindow
    var body: some View {
        HStack {
            Text("About")
            Spacer()
            Button("Open") {
                openWindow(id: "aboutWindow")
            }
            .buttonStyle(.bordered)
        }
        HStack {
            Text("Questions? → Hit me up on X!")
            Spacer()
            Link("Open", destination: URL(string: "https://x.com/frederikRiedel")!)
                .buttonStyle(.bordered)
        }
        HStack {
            Text("Share ICE Buddy")
            Spacer()
            ShareLink("Share", item: URL(string: "https://ice-buddy.riedel.wtf")!)
                .buttonStyle(.bordered)
                .labelStyle(.titleOnly)
        }
        HStack {
            Text("Launch at Login")
            Spacer()
            LaunchAtLogin.Toggle()
                .toggleStyle(.switch)
                .labelsHidden()
        }
        HStack {
            Text("Quit ICE Buddy")
            Spacer()
            Button("Quit") {
                NSApp.terminate(nil)
            }
        }
    }
}

#Preview {
    SettingsView()
}
