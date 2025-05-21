//
//  InformationView.swift
//  ICE Buddy
//
//  Created by Simon Kroner on 21.05.25.
//

import DBConnect
import SwiftUI
import TrainConnect

struct InformationView: View {
    @EnvironmentObject var connectDataHandler: ConnectDataHandler

    @State var isMapOpen: Bool = false
    @State var isExitAlertOpen: Bool = false
    @State var lastUpdateString: String? = nil
    @State var updateDateTimer: Timer? = nil
    var body: some View {
        if let trip = connectDataHandler.trip, let train = connectDataHandler.train {
            VStack {
                if #available(macOS 14.0, *) {
                    HStack {
                        Text("Open Map")
                        Spacer()
                        Button("Open") {
                            isMapOpen = true
                        }
                        .buttonStyle(.bordered)
                        .popover(isPresented: $isMapOpen, arrowEdge: .leading) {
                            JourneyMapView()
                                .frame(width: 480, height: 272)
                        }
                    }
                }
                HStack {
                    Text("Exit alert")
                    Spacer()
                    Button("Open") {
                        isExitAlertOpen = true
                    }
                    .buttonStyle(.bordered)
                    .popover(isPresented: $isExitAlertOpen, arrowEdge: .leading) {
                        Picker("Select exit alert", selection: Binding(
                            get: { connectDataHandler.exitAlertName },
                            set: { newValue in
                                connectDataHandler.setExitAlertName(newValue, completion: { isSet in
                                    if !isSet {
                                        showErrorExitAlertPresented()
                                    }
                                })
                            })) {
                                Text("No exit alert")
                                    .tag(nil as String?)
                                    .fontWeight(.bold)
                                ForEach(trip.trainStops, id: \.id) { trainStop in
                                    if !trainStop.hasPassed {
                                        Text(trainStop.trainStation.name)
                                            .tag(trainStop.trainStation.name)
                                    }
                                }
                            }
                            .pickerStyle(.inline)
                            .labelsHidden()
                            .padding()
                            .onChange(of: connectDataHandler.exitAlertName) { _ in
                                isExitAlertOpen = false
                            }
                    }
                }
                HStack {
                    Text("Internet Quality:")
                    Spacer()
                    Text(ucfirst(train.currentConnectivity) ?? "--")
                }
                Divider()

                HStack {
                    Text("Updated Infos:")
                    Spacer()
                    Text(lastUpdateString ?? "--")
                }
                .foregroundStyle(.secondary)
                .padding(.bottom, 3)
            }
            .onAppear {
                lastUpdateString = updateInfos(connectDataHandler.lastConnectDataUpdate)
                startUpdateDate()
            }
            .onDisappear {
                stopUpdateDate()
            }
        }
    }

    func showErrorExitAlertPresented() {
        let alert = NSAlert()
        alert.messageText = "No Permission"
        alert.informativeText = "Allow the notification to be sent when you leave the station"
        alert.addButton(withTitle: "OK")
        alert.alertStyle = .warning
        alert.runModal()
    }

    func startUpdateDate() {
        updateDateTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            lastUpdateString = updateInfos(connectDataHandler.lastConnectDataUpdate)
        }
    }

    func stopUpdateDate() {
        updateDateTimer?.invalidate()
        updateDateTimer = nil
    }

    func ucfirst(_ input: String?) -> String? {
        guard let input else { return nil }
        if input.isEmpty { return "" }
        let firstLetter = input.prefix(1).uppercased()
        if input.count == 1 { return firstLetter }
        let remainingLetters = input.dropFirst().lowercased()
        return firstLetter + remainingLetters
    }

    func updateInfos(_ date: Date?) -> String? {
        guard let date = date else { return nil }
        let currentDate = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.minute], from: date, to: currentDate)
        guard let minutes = components.minute else { return nil }

        if minutes < 1 {
            return String(localized: "Now")
        } else if minutes < 2 {
            return String(localized: "1 Minute ago")
        } else if minutes < 30 {
            return String(localized: "\(minutes) Minutes ago")
        } else if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return String(localized: "Today, \(formatter.string(from: date))")
        } else if calendar.isDateInYesterday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return String(localized: "Yesterday, \(formatter.string(from: date))")
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd.MM.yyyy, HH:mm"
            return formatter.string(from: date)
        }
    }
}

#Preview {
    if #available(macOS 14.0, *) {
        let connectDataHandler = ConnectDataHandler(demoMode: true)
        InformationView()
            .environmentObject(connectDataHandler)
            .frame(width: 350, height: 600)
    }
}
