//
//  JourneyMapView.swift
//  ICE Buddy
//
//  Created by Simon Kroner on 20.05.25.
//

import _MapKit_SwiftUI
import DBConnect
import SwiftUI
import TrainConnect

@available(macOS 14.0, *)
struct JourneyMapView: View {
    @EnvironmentObject var connectDataHandler: ConnectDataHandler
    @State var coordinates: [CLLocationCoordinate2D] = []

    var body: some View {
        if let status = connectDataHandler.train, let trip = connectDataHandler.trip {
            Map {
                if coordinates.count >= 2 {
                    MapPolyline(coordinates: coordinates)
                        .stroke(Color.red, lineWidth: 4)
                }
                Marker(coordinate: CLLocationCoordinate2DMake(status.latitude, status.longitude)) {
                    Image("menu bar icon")
                }
                if let exitAlertName = connectDataHandler.exitAlertName {
                    if let exitAlertStation = trip.trainStops.first(where: { $0.trainStation.name == exitAlertName }) {
                        if let coordinates = exitAlertStation.trainStation.coordinates {
                            Marker(coordinate: coordinates) {
                                Image(systemName: "alarm.fill")
                            }
                        }
                    }
                }
            }
            .onAppear {
                coordinates.removeAll()
                for trainStop in trip.trainStops {
                    if let unboundCoordinates = trainStop.trainStation.coordinates {
                        coordinates.append(unboundCoordinates)
                    }
                }
            }
        }
    }
}

#Preview {
    if #available(macOS 14.0, *) {
        let connectDataHandler = ConnectDataHandler(demoMode: true)
        JourneyMapView()
            .environmentObject(connectDataHandler)
            .frame(width: 600, height: 500)
    }
}
