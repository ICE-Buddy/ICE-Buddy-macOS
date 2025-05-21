//
//  ConnectDataHandler.swift
//  ICE Buddy
//
//  Created by Simon Kroner on 21.05.25.
//

import DBConnect
import Foundation
import SNCFConnect
import TrainConnect
import UserNotifications

class ConnectDataHandler: ObservableObject {
    @Published var train: TrainStatus?
    @Published var trip: TrainTrip?
    @Published var exitAlertName: String?
    @Published var lastConnectDataUpdate: Date?
    var exitAlertTimer: Timer?
    var demoMode: Bool
    var alertId: UUID

    let dataController = CombinedDataController(controllers:
        ICEDataController.shared,
        TGVDataController.shared
    )

    init(demoMode: Bool = false) {
        train = nil
        trip = nil
        exitAlertName = nil
        lastConnectDataUpdate = nil
        self.demoMode = demoMode
        alertId = UUID()
        deleteAllAlerts()
        Task {
            loadConnectData()
        }
    }

    public func setExitAlertName(_ name: String?, completion: @escaping (Bool) -> Void) {
        exitAlertName = name
        if exitAlertName == nil {
            stopExitAlertTimer()
            completion(true)
        } else {
            checkAlertPermission { granted in
                DispatchQueue.main.async {
                    if granted {
                        let exitAlertStation = self.trip?.trainStops.first(where: { $0.trainStation.name == self.exitAlertName })
                        if let actualArrival = exitAlertStation?.actualArrival {
                            self.addAlert(id: self.alertId.uuidString, date: actualArrival.addingTimeInterval(-600))
                            completion(true)
                        } else {
                            self.exitAlertName = nil
                            completion(true)
                        }
                    } else {
                        self.exitAlertName = nil
                        completion(false)
                    }
                }
            }
        }
    }

    public func updateData() {
        loadConnectData()
    }

    private func startExitAlertTimer() {
        exitAlertTimer = Timer.scheduledTimer(withTimeInterval: 600, repeats: true) { _ in
            self.loadConnectData()
            self.checkUpdateAlert()
        }
    }

    private func stopExitAlertTimer() {
        exitAlertTimer?.invalidate()
        exitAlertTimer = nil
    }

    private func deleteAlert() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [alertId.uuidString])
    }

    private func deleteAllAlerts() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    private func checkAlertPermission(completion: @escaping (Bool) -> Void) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional:
                completion(true)
            case .notDetermined:
                center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
                    DispatchQueue.main.async {
                        completion(granted)
                    }
                }
            default:
                completion(false)
            }
        }
    }

    func checkUpdateAlert() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let exitAlertStation = self.trip?.trainStops.first(where: { $0.trainStation.name == self.exitAlertName })
            let alertRequest = requests.first(where: { $0.identifier == self.alertId.uuidString })
            if let actualArrival = exitAlertStation?.actualArrival, let alertRequest = alertRequest, let calendarTrigger = alertRequest.trigger as? UNCalendarNotificationTrigger {
                if let alertDate = Calendar.current.date(from: calendarTrigger.dateComponents) {
                    if alertDate.addingTimeInterval(600) != actualArrival {
                        self.deleteAlert()
                        self.alertId = UUID()
                        self.addAlert(id: self.alertId.uuidString, date: actualArrival.addingTimeInterval(-600))
                    }
                }
            }
        }
    }

    func addAlert(id: String, date: Date) {
        let trigger: UNCalendarNotificationTrigger?
        if date < Date().addingTimeInterval(600) {
            trigger = nil
        } else {
            let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
            trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
            self.startExitAlertTimer()
        }
        let content = UNMutableNotificationContent()
        let (title, body) = generateAlertMessage()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if error != nil {
                self.exitAlertName = nil
            }
        }
    }

    private func generateAlertMessage() -> (title: String, body: String) {
        if let exitAlertStation = trip?.trainStops.first(where: { $0.trainStation.name == self.exitAlertName }), let track = exitAlertStation.trainTrack?.actual {
            let title = String(localized: "Exit alert \(exitAlertStation.trainStation.name)")
            let body = String(localized: "Arriving in 10 mins on track \(track).\nThank you for traveling with ICE Buddy today.")
            return (title, body)
        }
        let title = String(localized: "Exit alert")
        let body = String(localized: "Open ICE Buddy for more information.")
        return (title, body)
    }

    private func loadConnectData() {
        lastConnectDataUpdate = Date()
        dataController.loadTrainStatus(demoMode: demoMode) { status, _ in
            DispatchQueue.main.async {
                if let status = status {
                    self.train = status
                } else {
                    self.train = nil
                }
            }
        }
        dataController.loadTrip(demoMode: demoMode) { status, _ in
            DispatchQueue.main.async {
                if let status = status {
                    self.trip = status
                } else {
                    self.trip = nil
                }
            }
        }
    }
}
