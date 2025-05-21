//
//  MenuBarView.swift
//  ICE Buddy
//
//  Created by Simon Kroner on 19.05.25.
//

import DBConnect
import FredKit
import LaunchAtLogin
import SNCFConnect
import SwiftUI
import TrainConnect

struct MenuBarView: View {
    @EnvironmentObject var connectDataHandler: ConnectDataHandler

    var body: some View {
        VStack {
            if let train = connectDataHandler.train {
                IceHeaderView(trainIcon: train.trainType.trainIcon)
                    .padding(.leading)
                Divider()
                    .padding(.horizontal)
            }
            VStack {
                if (connectDataHandler.train != nil) && (connectDataHandler.trip != nil) {
                    TrainView()
                    Divider()
                    JourneyView()
                } else {
                    Text("Please connect to WiFionICE / Wifi@DB")
                }
                Divider()
                InformationView()
                HStack {
                    Text("ICE Buddy:")
                    Spacer()
                    Text("Version \(AppInfos.humanReadableVersionString)")
                }
                .foregroundStyle(.secondary)
                Divider()
                SettingsView()
            }
            .padding(.horizontal)
            .padding(.bottom)
            .onAppear {
                connectDataHandler.updateData()
            }
        }
        .padding(.top)
    }
}

#Preview {
    let connectDataHandler = ConnectDataHandler(demoMode: true)
    MenuBarView()
        .environmentObject(connectDataHandler)
        .frame(width: 350, height: 600)
}
