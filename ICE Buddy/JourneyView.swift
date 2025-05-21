//
//  JourneyView.swift
//  ICE Buddy
//
//  Created by Simon Kroner on 20.05.25.
//

import DBConnect
import SwiftUI
import TrainConnect

struct JourneyView: View {
    @EnvironmentObject var connectDataHandler: ConnectDataHandler
    var body: some View {
        if let trip = connectDataHandler.trip {
            VStack(spacing: 0) {
                ForEach(trip.trainStops, id: \.id) { trainStop in
                    HStack {
                        JourneyBadgeView(hasPassed: trainStop.hasPassed)
                        if trainStop.hasPassed {
                            HStack {
                                Text(trainStop.trainStation.name)
                                Spacer()
                                Text(timeString(from: trainStop.actualDeparture) ?? timeString(from: trainStop.scheduledDeparture) ?? "--")
                                    .frame(width: 40, alignment: .trailing)
                                if !trainStop.arrivalDelay.isEmpty {
                                    Text(trainStop.departureDelay)
                                        .frame(width: 20, alignment: .trailing)
                                } else {
                                    Text("")
                                        .frame(width: 20, alignment: .trailing)
                                }
                                Text("Track \(trainStop.trainTrack?.actual ?? trainStop.trainTrack?.scheduled ?? "--")")
                                    .frame(width: 65, alignment: .trailing)
                            }
                            .foregroundStyle(.secondary)
                        } else {
                            Text(trainStop.trainStation.name)
                            if let exitAlertName = connectDataHandler.exitAlertName, trainStop.trainStation.name == exitAlertName {
                                Image(systemName: "alarm.fill")
                            }
                            Spacer()
                            Text(timeString(from: trainStop.actualArrival) ?? timeString(from: trainStop.scheduledArrival) ?? "--")
                                .frame(width: 40, alignment: .trailing)
                            if !trainStop.arrivalDelay.isEmpty {
                                Text(trainStop.arrivalDelay)
                                    .foregroundStyle(.red)
                                    .frame(width: 20, alignment: .trailing)
                                // TODO: every time red or sometimes green?
                            } else {
                                Text("")
                                    .frame(width: 20, alignment: .trailing)
                            }
                            Text("Track \(trainStop.trainTrack?.actual ?? trainStop.trainTrack?.scheduled ?? "--")")
                                .frame(width: 65, alignment: .trailing)
                        }
                    }
                    .frame(height: 20)
                }
            }
        }
    }

    func timeString(from date: Date?) -> String? {
        guard let date = date else { return nil }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
}

#Preview {
    let connectDataHandler = ConnectDataHandler(demoMode: true)
    JourneyView()
        .environmentObject(connectDataHandler)
        .frame(width: 300, height: 400)
}
