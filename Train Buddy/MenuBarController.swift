//
//  MenuBarController.swift
//  Train Buddy
//
//  Created by Frederik Riedel on 16.11.21.
//

import Foundation
import AppKit
import LaunchAtLogin
import FredKit
import UserNotifications
import DBConnect
import TrainConnect
import SNCFConnect
import OnboardConnect

let demoMode = ProcessInfo.processInfo.arguments.contains("--demo")

class MenuBarController: NSObject {
    
    static let shared = MenuBarController()
    
    let dataController = CombinedDataController(controllers:
                                                ICEDataController.shared,
                                                TGVDataController.shared,
                                                RailnetDataController.shared,
                                                CDDataController.shared,
                                                DBRegioDataController.shared
    )
    
    private var iceStatusItem: NSStatusItem?
    private var currentSpeedStatusItem: NSStatusItem?
    
    let iceHeaderMenuItem = NSMenuItem()
    
    var journeyViewControllers = [JourneyStopCustomViewController]()
    
    let iceBuddyHeaderMenuItem = NSMenuItem(title: localized("Train Buddy (Version %@)", AppInfos.humanReadableVersionString), action: nil, keyEquivalent: "")
    let lastUpdateMenuitem = NSMenuItem(title: "Updated Infos: Just now".localized, action: nil, keyEquivalent: "")
    
    let currentSpeedMenuItem = NSMenuItem(title: "– km/h".localized, action: nil, keyEquivalent: "")
    let trainTypeMenuItem = NSMenuItem(title: "–".localized, action: nil, keyEquivalent: "")
    
    let connectionMenuItem = NSMenuItem(title: "– → –".localized, action: nil, keyEquivalent: "")
    let nextStopTitleMenuItem = NSMenuItem(title: "Next Stop:".localized, action: nil, keyEquivalent: "")
    let nextStopValueMenuItem = NSMenuItem(title: "–, –:–".localized, action: nil, keyEquivalent: "")
    let nextStopTrackMenuItem = NSMenuItem(title: "Track: –".localized, action: nil, keyEquivalent: "")
    
    let ausstiegsAlarmMenuItem = NSMenuItem(title: "Exit alarm".localized, action: nil, keyEquivalent: "")
    
    let internetQualityMenuitem = NSMenuItem(title: "Internet Quality: –".localized, action: nil, keyEquivalent: "")

    
    private let diagnosticsController = APIDiagnosticsController()
    let reportAPIProblemMenuItem = NSMenuItem(title: "Report API problem…".localized, action: nil, keyEquivalent: "")
    let disconnectedReportAPIProblemMenuItem = NSMenuItem(title: "Report API problem…".localized, action: nil, keyEquivalent: "")

    let aboutMenuItem = NSMenuItem(title: "About".localized, action: nil, keyEquivalent: "")
    let launchAtLoginMenuItem = NSMenuItem(title: "Launch at Login".localized, action: nil, keyEquivalent: "")
    let twitterMenuItem = NSMenuItem(title: "Questions? → Hit me up on Twitter!".localized, action: nil, keyEquivalent: "")
    let quitMenuItem = NSMenuItem(title: "Quit Train Buddy".localized, action: nil, keyEquivalent: "")
    
    let mapVC = JourneyMapViewController()
    let showMapMenuItem = NSMenuItem(title: "Route on Map".localized, action: nil, keyEquivalent: "")
    let mapMenuItem = NSMenuItem()
    
    let menu = NSMenu(title: "Train Buddy Active")
    let disconnectedMenu = NSMenu(title: "Train Buddy Disconnected")
    
    let shareICEBuddy = NSMenuItem(title: "Share Train Buddy".localized, action: nil, keyEquivalent: "")
    
    var continousUpdateTimer: Timer?
    var speedUpdateTimer: Timer?
    var ausstiegsalarmTimer: Timer?
    
    func refreshSpeedMenuItem() {
        let statusBar = NSStatusBar.system
        
        speedUpdateTimer?.invalidate()
        
        if !isSpeedPinned {
            if let currentSpeedStatusItem = currentSpeedStatusItem {
                statusBar.removeStatusItem(currentSpeedStatusItem)
                self.currentSpeedStatusItem = nil
            }
        } else {
            self.refreshSpeedInStatusBar()
            speedUpdateTimer = Timer.scheduledTimer(withTimeInterval: 11, repeats: true) { _ in
                self.refreshSpeedInStatusBar()
            }
            if let timer = speedUpdateTimer { RunLoop.main.add(timer, forMode: .common) }
        }
        
        ausstiegsalarmTimer?.invalidate()
        
        self.refreshAusstiegsAlarmNotification()
        ausstiegsalarmTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval.minute, repeats: true, block: { _ in
            if let _ = MenuBarController.ausstiegsAlarmStation {
                self.refreshAusstiegsAlarmNotification()
            }
        })
        
    }
    
    private func refreshAusstiegsAlarmNotification() {
        guard MenuBarController.ausstiegsAlarmStation != nil else { return }
        self.dataController.loadSnapshot(demoMode: demoMode) { snapshot, error in
            if let tripData = snapshot?.trip {
                let exitStop = tripData.trainStops.first { stop in
                    stop.trainStation.name == MenuBarController.ausstiegsAlarmStation
                }
                
                if let stop = exitStop, !stop.hasPassed, !stop.isCancelled {
                    self.scheduleAusstiegsAlarm(for: stop)
                } else {
                    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["ice_buddy_ausstiegsalarm"])
                }
            }
        }
    }
    
    private func scheduleAusstiegsAlarm(for stop: TrainStop) {
        UNUserNotificationCenter.current().getNotificationSettings { (notificationSettings) in
            switch notificationSettings.authorizationStatus {
            case .notDetermined:
                print("not determined")
                self.requestPushAuthorization { success in
                    if success { DispatchQueue.main.async { self.scheduleLocalNotification(stop: stop) } }
                }
            case .authorized:
                print("authorized")
                DispatchQueue.main.async { self.scheduleLocalNotification(stop: stop) }
            case .denied:
                print("Application Not Allowed to Display Notifications")
            case .provisional:
                DispatchQueue.main.async { self.scheduleLocalNotification(stop: stop) }
            @unknown default:
                print("default")
            }
        }
    }
    
    private func requestPushAuthorization(completionHandler: @escaping (_ success: Bool) -> ()) {
        // Request Authorization
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { (success, error) in
            if let error = error {
                print("Request Authorization Failed (\(error), \(error.localizedDescription))")
            }
            
            completionHandler(success)
        }
    }
    
    private var imminentAlarmStation: String?

    private func scheduleLocalNotification(stop: TrainStop) {
        guard stop.trainStation.name == MenuBarController.ausstiegsAlarmStation else { return }
        // Create Notification Content
        let notificationContent = UNMutableNotificationContent()
        
        if let actualArrivalTime = (stop.actualArrival ?? stop.scheduledArrival), actualArrivalTime > Date() {
            notificationContent.title = localized("Exit alarm: %@", stop.trainStation.name)
            if let track = stop.trainTrack?.actual {
                notificationContent.subtitle = localized("Arriving soon on platform %@.", track)
            } else {
                notificationContent.subtitle = "Arriving soon.".localized
            }
            notificationContent.body = "Your stop is approaching.".localized
            
            let triggerDate = actualArrivalTime.addingTimeInterval(-10 * TimeInterval.minute)
            
            if imminentAlarmStation != stop.trainStation.name {
                // Add Trigger
                
                let notificationTrigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, triggerDate.timeIntervalSinceNow), repeats: false)
                
                // Create Notification Request
                let notificationRequest = UNNotificationRequest(identifier: "ice_buddy_ausstiegsalarm", content: notificationContent, trigger: notificationTrigger)
                
                // Add Request to User Notification Center
                if triggerDate <= Date() { imminentAlarmStation = stop.trainStation.name }
                UNUserNotificationCenter.current().add(notificationRequest) { (error) in
                    if let error = error {
                        DispatchQueue.main.async { self.imminentAlarmStation = nil }
                        print("Unable to Add Notification Request (\(error), \(error.localizedDescription))")
                    }
                }
            }
        }
    }
    
    private func refreshSpeedInStatusBar() {
        dataController.loadSnapshot(demoMode: demoMode) { snapshot, _ in
            guard self.isSpeedPinned, let status = snapshot?.status else {
                self.removeSpeedStatusItem()
                return
            }
            // Keep the same item across updates. Recreating it loses its position/visibility on Tahoe.
            if self.currentSpeedStatusItem == nil {
                let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
                item.autosaveName = "current-speed"
                let speedMenu = NSMenu()
                let unpin = NSMenuItem(title: "Unpin from Menu Bar".localized, action: #selector(self.toggleSpeedPin), keyEquivalent: "")
                unpin.target = self
                speedMenu.addItem(unpin)
                item.menu = speedMenu
                self.currentSpeedStatusItem = item
            }
            let formatter = MeasurementFormatter()
            formatter.unitOptions = .providedUnit
            self.currentSpeedStatusItem?.button?.title = formatter.string(from: status.currentSpeed)
        }
    }

    private func removeSpeedStatusItem() {
        if let item = currentSpeedStatusItem { NSStatusBar.system.removeStatusItem(item) }
        currentSpeedStatusItem = nil
    }

    var refreshAusstiegsAlarmMenuNextTime = false
    private func refreshAusstiegsalarmMenu(stops: [TrainStop]) {
        refreshAusstiegsAlarmMenuNextTime = false
        let submenu = NSMenu()
        let explaination = NSMenuItem(title: "Get reminded 10 mins before you reach your stop".localized, action: nil, keyEquivalent: "")
        submenu.addItem(explaination)
        let disable = NSMenuItem(title: "Disable exit alarm".localized, action: #selector(disableExitAlarm), keyEquivalent: "")
        disable.target = self
        submenu.addItem(disable)
        submenu.addItem(NSMenuItem.separator())
        
        let availableStopsToSelect = stops.map { stop -> NSMenuItem in
            let menuItem = NSMenuItem(title: stop.trainStation.name, action: #selector(didSelectStop), keyEquivalent: "")
            if let actualArrivalTime = (stop.actualArrival ?? stop.scheduledArrival), !stop.isCancelled {
                if stop.trainStation.name == MenuBarController.ausstiegsAlarmStation {
                    menuItem.state = .on
                } else {
                    menuItem.state = .off
                }
                if actualArrivalTime.isInFuture {
                    menuItem.target = self
                }
            }
            
            return menuItem
        }
        
        availableStopsToSelect.forEach { menuItem in
            submenu.addItem(menuItem)
        }
        
        self.ausstiegsAlarmMenuItem.submenu = submenu
    }
    
    @objc func didSelectStop(sender: NSMenuItem) {
        clearExitAlarmNotification()
        MenuBarController.ausstiegsAlarmStation = sender.title
        refreshAusstiegsAlarmMenuNextTime = true
        self.refreshAusstiegsAlarmNotification()
    }
    
    @objc private func disableExitAlarm() {
        MenuBarController.ausstiegsAlarmStation = nil
        clearExitAlarmNotification()
        refreshAusstiegsAlarmMenuNextTime = true
        refreshMetaData()
    }

    private func clearExitAlarmNotification() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["ice_buddy_ausstiegsalarm"])
        center.removeDeliveredNotifications(withIdentifiers: ["ice_buddy_ausstiegsalarm"])
        imminentAlarmStation = nil
    }

    static var ausstiegsAlarmStation: String? {
        get {
            if let value = NSUserDefaultsController.shared.defaults.value(forKey: "ausstiegsAlarmStation") as? String {
                return value
            }
            
            return nil
        }
        
        set {
            NSUserDefaultsController.shared.defaults.setValue(newValue, forKey: "ausstiegsAlarmStation")
        }
    }
    
    func refreshMenuBarItems() {
        
        self.refreshSpeedMenuItem()
        let statusBar = NSStatusBar.system
        
        iceStatusItem = statusBar.statusItem(withLength: NSStatusItem.squareLength)
        iceStatusItem?.autosaveName = "ice-buddy"
        
        

        iceStatusItem?.button?.image = NSImage(named: "menu bar icon")
        iceStatusItem?.button?.setAccessibilityLabel("Train Buddy")
        
        launchAtLoginMenuItem.action = #selector(toggleLaunchAtLogin)
        launchAtLoginMenuItem.target = self
        
        openLoginMenuItem.action = #selector(openWifiLogin)
        openLoginMenuItem.target = self
        
        twitterMenuItem.action = #selector(hmuTwitter)
        twitterMenuItem.target = self
        
        reportAPIProblemMenuItem.action = #selector(reportAPIProblem)
        reportAPIProblemMenuItem.target = self

        aboutMenuItem.action = #selector(showAbout)
        aboutMenuItem.target = self
        
        quitMenuItem.action = #selector(quitApp)
        quitMenuItem.target = self
        
        shareICEBuddy.submenu = NSSharingServicePicker.menu(forSharingItems: [URL(string: "https://ice-buddy.riedel.wtf")!])
        
        iceHeaderMenuItem.view = iceHeaderVC.view
        
        let mapMenu = NSMenu(title: "Map Menu")
        
        showMapMenuItem.submenu = mapMenu
        mapMenuItem.view = mapVC.view
        mapMenu.addItem(mapMenuItem)
        
        self.refreshMenuBarMenues()
    }
    
    @objc func toggleLaunchAtLogin() {
        LaunchAtLogin.isEnabled = !LaunchAtLogin.isEnabled
    }
    
    @objc func openWifiLogin() {
        let url = URL(string:"http://LogIn.WIFIonICE.de")!
        NSWorkspace.shared.open([url],
                                withAppBundleIdentifier:"com.apple.Safari",
                                options: [],
                                additionalEventParamDescriptor: nil,
                                launchIdentifiers: nil)
    }
    
    @objc func hmuTwitter() {
        let url = URL(string:"https://twitter.com/frederikRiedel")!
        NSWorkspace.shared.open([url],
                                withAppBundleIdentifier:"com.apple.Safari",
                                options: [],
                                additionalEventParamDescriptor: nil,
                                launchIdentifiers: nil)
    }
    
    let iceHeaderVC = ICEHeader()
    private func refreshMenuBarMenues() {
        
        menu.removeAllItems()
        self.journeyViewControllers.removeAll()
        
        
        let speedPinMenu = NSMenu()
        var pinSpeedButtonTitle = "Pin current speed to Menu Bar".localized
        if isSpeedPinned {
            pinSpeedButtonTitle = "Un-pin current speed to Menu Bar".localized
        }
        let pinSpeedMenuItem = NSMenuItem(title: pinSpeedButtonTitle, action: #selector(toggleSpeedPin), keyEquivalent: "")
        pinSpeedMenuItem.target = self
        speedPinMenu.addItem(pinSpeedMenuItem)
        currentSpeedMenuItem.submenu = speedPinMenu
        
        ausstiegsAlarmMenuItem.submenu = NSMenu()
        
        menu.delegate = self
        iceStatusItem?.menu = menu;
        
        self.menu.addItem(iceHeaderMenuItem)
        self.menu.addItem(NSMenuItem.separator())
        self.menu.addItem(connectionMenuItem)
        self.menu.addItem(currentSpeedMenuItem)
        self.menu.addItem(trainTypeMenuItem)
        self.menu.addItem(NSMenuItem.separator())
        // connection stops dynamically added inbetween
        self.menu.addItem(NSMenuItem.separator())
        self.menu.addItem(showMapMenuItem)
        self.menu.addItem(ausstiegsAlarmMenuItem)
        self.menu.addItem(internetQualityMenuitem)
        self.menu.addItem(NSMenuItem.separator())
        self.menu.addItem(iceBuddyHeaderMenuItem)
        self.menu.addItem(lastUpdateMenuitem)
        self.menu.addItem(NSMenuItem.separator())
        self.menu.addItem(reportAPIProblemMenuItem)
        self.menu.addItem(aboutMenuItem)
        self.menu.addItem(shareICEBuddy)
        self.menu.addItem(launchAtLoginMenuItem)
        self.menu.addItem(twitterMenuItem)
        self.menu.addItem(quitMenuItem)
        
        self.menu.update()
        self.iceStatusItem?.menu = self.menu
        self.refreshMetaData()
        
    }
    
    @objc func toggleSpeedPin() {
        self.isSpeedPinned = !self.isSpeedPinned
        self.refreshSpeedMenuItem()
        refreshMenuBarMenues()
    }
    
    var isSpeedPinned: Bool {
        get {
            if let value = NSUserDefaultsController.shared.defaults.value(forKey: "speed-pinned") as? Bool {
                return value
            }
            
            return false
        }
        
        set {
            NSUserDefaultsController.shared.defaults.setValue(newValue, forKey: "speed-pinned")
        }
    }
    
    
    let disconnectedMenuItem = NSMenuItem(title: "Connect to supported onboard Wi-Fi: ICE, TGV, ÖBB, ČD or DB Regio".localized, action: nil, keyEquivalent: "")
    let openLoginMenuItem = NSMenuItem(title: "Open LogIn.WIFIonICE.de in Safari".localized, action: nil, keyEquivalent: "")
    
    let disconnectedLaunchAtLoginMenuItem = NSMenuItem(title: "Launch at Login".localized, action: nil, keyEquivalent: "")
    let disconnectedTwitterMenuItem = NSMenuItem(title: "Questions? → Hit me up on Twitter!".localized, action: nil, keyEquivalent: "")
    let disconnectedqQitMenuItem = NSMenuItem(title: "Quit Train Buddy".localized, action: nil, keyEquivalent: "")
    let disconnectedAboutMenuItem = NSMenuItem(title: "About".localized, action: nil, keyEquivalent: "")
    
    var isConnected = true
    private func showDisconnectedMenu() {
        isConnected = false
        removeSpeedStatusItem()
        
        disconnectedLaunchAtLoginMenuItem.action = #selector(toggleLaunchAtLogin)
        disconnectedLaunchAtLoginMenuItem.target = self
        
        disconnectedTwitterMenuItem.action = #selector(hmuTwitter)
        disconnectedTwitterMenuItem.target = self
        
        disconnectedReportAPIProblemMenuItem.action = #selector(reportAPIProblem)
        disconnectedReportAPIProblemMenuItem.target = self

        disconnectedAboutMenuItem.action = #selector(showAbout)
        disconnectedAboutMenuItem.target = self
        
        disconnectedqQitMenuItem.action = #selector(quitApp)
        disconnectedqQitMenuItem.target = self
        
        disconnectedMenu.removeAllItems()
        disconnectedMenu.delegate = self
        disconnectedMenu.addItem(disconnectedMenuItem)
        self.disconnectedMenu.addItem(NSMenuItem.separator())
        self.disconnectedMenu.addItem(disconnectedReportAPIProblemMenuItem)
        self.disconnectedMenu.addItem(disconnectedAboutMenuItem)
        self.disconnectedMenu.addItem(disconnectedLaunchAtLoginMenuItem)
        self.disconnectedMenu.addItem(disconnectedTwitterMenuItem)
        self.disconnectedMenu.addItem(disconnectedqQitMenuItem)
        self.disconnectedMenu.update()
        self.iceStatusItem?.menu = disconnectedMenu
    }
    
    
    
    @objc func reportAPIProblem() {
        diagnosticsController.showReport()
    }

    @objc func showAbout() {
        let aboutVC = AboutViewController()
        let window = NSWindow(contentViewController: aboutVC)
        let windowController = NSWindowController(window: window)
        windowController.showWindow(nil)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func quitApp() {
        NSApp.terminate(nil)
    }
    
    @objc func refreshMetaData() {
        
        if LaunchAtLogin.isEnabled {
            launchAtLoginMenuItem.state = .on
            disconnectedLaunchAtLoginMenuItem.state = .on
        } else {
            launchAtLoginMenuItem.state = .off
            disconnectedLaunchAtLoginMenuItem.state = .off
        }

        dataController.loadSnapshot(demoMode: demoMode) { snapshot, _ in
            guard let snapshot = snapshot else {
                self.showDisconnectedMenu()
                return
            }
            self.isConnected = true
            let tripData = snapshot.trip
            if let status = snapshot.status {
                let formatter = MeasurementFormatter()
                formatter.unitOptions = .providedUnit
                let speedString = formatter.string(from: status.currentSpeed)
                self.currentSpeedMenuItem.title = speedString
                self.currentSpeedStatusItem?.button?.title = speedString
                self.internetQualityMenuitem.title = localized("Internet quality: %@", status.currentConnectivity ?? "Unknown".localized)
            } else {
                self.currentSpeedMenuItem.title = "Speed unavailable".localized
                self.internetQualityMenuitem.title = "Internet quality unavailable".localized
                self.removeSpeedStatusItem()
            }
            self.trainTypeMenuItem.title = localized("Train model: %@", snapshot.trainType?.trainModel ?? "Unknown".localized)
            self.lastUpdateMenuitem.title = localized("Updated: %@", snapshot.fetchedAt.humanReadableDateAndTimeString)
            self.iceHeaderVC.imageView.image = snapshot.trainType?.trainIcon ?? ICETrainType(tzn: "").trainIcon
            self.iceHeaderVC.imageView.setAccessibilityLabel(snapshot.trainType?.trainModel ?? "Train".localized)
            self.iceStatusItem?.menu = self.menu
            self.mapVC.stops = tripData.trainStops
            if let origin = tripData.trainStops.first, let destination = tripData.trainStops.last {
                self.connectionMenuItem.title = "\(tripData.serviceName): \(origin.trainStation.name) → \(destination.trainStation.name)"
            }



            if self.refreshAusstiegsAlarmMenuNextTime {
                self.refreshAusstiegsalarmMenu(stops: tripData.trainStops)
            }

            if let nextStop = tripData.trainStops.nextStop {
                if let humanReadableArrivalTime = (nextStop.actualArrival ?? nextStop.scheduledArrival)?.minuteTimeString {
                    self.nextStopValueMenuItem.title = "\(humanReadableArrivalTime), \(nextStop.trainStation.name)"
                }

                if let track = nextStop.trainTrack?.actual {
                    self.nextStopTrackMenuItem.title = "Track: \(track)"
                } else {
                    self.nextStopTrackMenuItem.title = ""
                }
            }

            if self.journeyViewControllers.isEmpty {
                self.journeyViewControllers = tripData.trainStops.enumerated().map({ enumeration in
                    return JourneyStopCustomViewController(stopIndex: enumeration.offset, journey: tripData)
                })

                self.journeyViewControllers.enumerated().forEach { enumeration in
                    let index = 6 + enumeration.offset
                    let stopMenuItem = NSMenuItem()
                    stopMenuItem.view = enumeration.element.view
                    self.menu.insertItem(stopMenuItem, at: index)
                }

                self.refreshAusstiegsalarmMenu(stops: tripData.trainStops)

            } else if tripData.trainStops.count != self.journeyViewControllers.count {
                self.journeyViewControllers.removeAll()
                self.refreshMenuBarMenues()
                self.refreshAusstiegsalarmMenu(stops: tripData.trainStops)

            } else {
                self.journeyViewControllers.forEach { journeyVC in
                    journeyVC.journey = tripData
                }
            }
            self.iceStatusItem?.menu = self.menu
        }
    }
    
#if DEBUG
    var debugCounter = 0
#endif
}

extension MenuBarController: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        
#if DEBUG
        debugCounter += 1
#endif
        
        if self.isConnected == false {
            self.refreshMenuBarMenues()
            self.isConnected = true
        }
            
        self.refreshMetaData()
        
        continousUpdateTimer?.invalidate()
        continousUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { _ in
            if self.isConnected {
                self.refreshMetaData()
            } else {
                self.continousUpdateTimer?.invalidate()
            }
        })
        
        RunLoop.main.add(continousUpdateTimer!, forMode: .common)
    }
    
    func menuDidClose(_ menu: NSMenu) {
        continousUpdateTimer?.invalidate()
    }
}

private extension String {
    var localized: String { NSLocalizedString(self, comment: "") }
}

private func localized(_ key: String, _ arguments: CVarArg...) -> String {
    String(format: NSLocalizedString(key, comment: ""), locale: Locale.current, arguments: arguments)
}
