//
//  TrainView.swift
//  ICE Buddy
//
//  Created by Simon Kroner on 20.05.25.
//

import DBConnect
import SNCFConnect
import SwiftUI
import TrainConnect

struct TrainView: View {
    @EnvironmentObject var connectDataHandler: ConnectDataHandler
    var body: some View {
        if let trip = connectDataHandler.trip, let train = connectDataHandler.train {
            VStack {
                HStack {
                    Text("\(trip.train) \(trip.vzn):")
                    Spacer()
                    Text("\(trip.trainStops.first?.trainStation.name ?? "--") → \(trip.trainStops.last?.trainStation.name ?? "--")")
                }
                .padding(.bottom, 0.5)
                HStack {
                    Text("Speed:")
                    Spacer()
                    Text(train.currentSpeed.description)
                }
                .padding(.bottom, 0.5)
                HStack {
                    Text("Train Model:")
                    Spacer()
                    Text("\(train.trainType.trainModel)")
                }
                .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    let connectDataHandler = ConnectDataHandler(demoMode: true)
    TrainView()
        .environmentObject(connectDataHandler)
        .frame(width: 300, height: 400)
}
