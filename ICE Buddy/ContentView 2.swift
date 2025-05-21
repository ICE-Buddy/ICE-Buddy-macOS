//
//  ContentView.swift
//  ICE Buddy
//
//  Created by Simon Kroner on 19.05.25.
//

import DBConnect
import LaunchAtLogin
import SNCFConnect
import SwiftUI
import TrainConnect

struct ContentView: View {
    @Environment(\.openWindow) private var openWindow
    @State var demoMode = true
    @State var trainStatus: TrainStatus? = nil
    @State var tripStatus: TrainTrip? = nil
    @State var isMapOpen: Bool = false
    let dataController = CombinedDataController(controllers:
        ICEDataController.shared,
        TGVDataController.shared
    )

    var body: some View {
        VStack {
            if let unwrappedStatus = trainStatus {
                IceHeaderView(trainIcon: unwrappedStatus.trainType.trainIcon)
                    .padding(.leading)
                Divider()
                    .padding(.horizontal)
            }
            VStack {
                if let unwrappedStatus = trainStatus, let unwrappedTrip = tripStatus {
                    TrainView(status: unwrappedStatus, trip: unwrappedTrip)
                    Divider()
                    JourneyView(trip: unwrappedTrip)
                } else {
                    Text("Please connect to WiFionICE / Wifi@DB")
                }
                Divider()
                if #available(macOS 14.0, *) {
                    if let unwrappedTrip = tripStatus, let unwrappedStatus = trainStatus {
                        HStack {
                            Text("Open Map")
                            Spacer()
                            Button("Open") {
                                isMapOpen = true
                            }
                            .buttonStyle(.bordered)  
                            .popover(isPresented: $isMapOpen, arrowEdge: .leading) {
                                JourneyMapView(trip: unwrappedTrip, status: unwrappedStatus)
                                    .frame(width: 500, height: 500)
                            }
                        }
                    }
                }
                HStack {
                    Text("Internet Quality:")
                    Spacer()
                    Text(ucfirst(trainStatus?.currentConnectivity) ?? "--")
                }
                Divider()
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
            .padding(.horizontal)
            .padding(.bottom)
            .onAppear {
                dataController.loadTrainStatus(demoMode: demoMode) { status, _ in
                    if let status = status {
                        trainStatus = status
                    } else {
                        trainStatus = nil
                    }
                }
                dataController.loadTrip(demoMode: demoMode) { status, _ in
                    if let status = status {
                        tripStatus = status
                    } else {
                        tripStatus = nil
                    }
                }
            }
        }
        .padding(.top)
    }
    
    
    func ucfirst(_ input: String?) -> String? {
        guard let input else { return nil }
        if input.isEmpty { return "" }
        let firstLetter = input.prefix(1).uppercased()
        if input.count == 1 { return firstLetter }
        let remainingLetters = input.dropFirst().lowercased()
        return firstLetter + remainingLetters
    }
}

#Preview {
    ContentView(demoMode: true)
        .frame(width: 300, height: 600)
}
