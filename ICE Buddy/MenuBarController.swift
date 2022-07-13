//
//  MenuBarController.swift
//  ICE Buddy
//
//  Created by Frederik Riedel on 16.11.21.
//

import Foundation
import AppKit
import LaunchAtLogin
import FredKit
import UserNotifications
import StoreKit
import DBConnect
import TrainConnect
import SNCFConnect

let demoMode: Bool = true

class MenuBarController: NSObject {
    
    static let shared = MenuBarController()
    
    let dataController = CombinedDataController(controllers:
                                                ICEDataController.shared
//                                                TGVDataController.shared
    )
    
    private var iceStatusItem: NSStatusItem?
    private var currentSpeedStatusItem: NSStatusItem?
    
    let iceHeaderMenuItem = NSMenuItem()
    
    var journeyViewControllers = [JourneyStopCustomViewController]()
    
    let iceBuddyHeaderMenuItem = NSMenuItem(title: "ICE Buddy (Version \(AppInfos.humanReadableVersionString))", action: nil, keyEquivalent: "")
    let lastUpdateMenuitem = NSMenuItem(title: "Updated Infos: Just now", action: nil, keyEquivalent: "")
    
    let currentSpeedMenuItem = NSMenuItem(title: "– km/h", action: nil, keyEquivalent: "")
    let trainTypeMenuItem = NSMenuItem(title: "–", action: nil, keyEquivalent: "")
    
    let connectionMenuItem = NSMenuItem(title: "– → –", action: nil, keyEquivalent: "")
    let nextStopTitleMenuItem = NSMenuItem(title: "Next Stop:", action: nil, keyEquivalent: "")
    let nextStopValueMenuItem = NSMenuItem(title: "–, –:–", action: nil, keyEquivalent: "")
    let nextStopTrackMenuItem = NSMenuItem(title: "Track: –", action: nil, keyEquivalent: "")
    
    let ausstiegsAlarmMenuItem = NSMenuItem(title: "Ausstiegsalarm", action: nil, keyEquivalent: "")
    
    let internetQualityMenuitem = NSMenuItem(title: "Internet Quality: –", action: nil, keyEquivalent: "")

    
    let aboutMenuItem = NSMenuItem(title: "About", action: nil, keyEquivalent: "")
    let launchAtLoginMenuItem = NSMenuItem(title: "Launch at Login", action: nil, keyEquivalent: "")
    let twitterMenuItem = NSMenuItem(title: "Questions? → Hit me up on Twitter!", action: nil, keyEquivalent: "")
    let quitMenuItem = NSMenuItem(title: "Quit ICE Buddy", action: nil, keyEquivalent: "")
    
    let mapVC = JourneyMapViewController()
    let showMapMenuItem = NSMenuItem(title: "Route on Map", action: nil, keyEquivalent: "")
    let mapMenuItem = NSMenuItem()
    
    let menu = NSMenu(title: "ICE Buddy Active")
    let disconnectedMenu = NSMenu(title: "ICE Buddy Disconnected")
    
    let shareICEBuddy = NSMenuItem(title: "Share ICE Buddy", action: nil, keyEquivalent: "")
    
    var continousUpdateTimer: Timer?
    var speedUpdateTimer: Timer?
    var ausstiegsalarmTimer: Timer?
    
    func refreshSpeedMenuItem() {
        let statusBar = NSStatusBar.system
        
        speedUpdateTimer?.invalidate()
        
        if !isSpeedPinned {
            if let currentSpeedStatusItem = currentSpeedStatusItem {
                statusBar.removeStatusItem(currentSpeedStatusItem)
            }
        } else {
            self.refreshSpeedInStatusBar()
            speedUpdateTimer = Timer.scheduledTimer(withTimeInterval: 11, repeats: true) { _ in
                self.refreshSpeedInStatusBar()
            }
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
        self.dataController.loadTrip(demoMode: demoMode) { trip, error in
            if let tripData = trip {
                let exitStop = tripData.trainStops.first { stop in
                    stop.trainStation.name == MenuBarController.ausstiegsAlarmStation
                }
                
                if let stop = exitStop {
                    self.scheduleAusstiegsAlarm(for: stop)
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
                    self.scheduleLocalNotification(stop: stop)
                }
            case .authorized:
                print("authorized")
                self.scheduleLocalNotification(stop: stop)
            case .denied:
                print("Application Not Allowed to Display Notifications")
            case .provisional:
                print("provisional")
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
    
    private func scheduleLocalNotification(stop: TrainStop) {
        // Create Notification Content
        let notificationContent = UNMutableNotificationContent()
        
        if let actualArrivalTime = stop.actualArrival {
            // Configure Notification Content
            
//            let timeToArrive = actualArrivalTime.timeIntervalSinceNow
//            let minutesToArrive = Int(timeToArrive / TimeInterval.minute)
            
            notificationContent.title = "Ausstiegsalarm \(stop.trainStation.name)"
            if let track = stop.trainTrack?.actual {
                notificationContent.subtitle = "Arriving in 10 mins on track \(track)."
            } else {
                notificationContent.subtitle = "Arriving in 10 mins."
            }
            notificationContent.body = "Thank you for traveling with ICE Buddy today."
            
            let triggerDate = actualArrivalTime.addingTimeInterval(-10 * TimeInterval.minute)
            
            if triggerDate.isInFuture {
                // Add Trigger
                
                let notificationTrigger = UNTimeIntervalNotificationTrigger(timeInterval: triggerDate.timeIntervalSinceNow, repeats: false)
                
                // Create Notification Request
                let notificationRequest = UNNotificationRequest(identifier: "ice_buddy_ausstiegsalarm", content: notificationContent, trigger: notificationTrigger)
                
                // Add Request to User Notification Center
                UNUserNotificationCenter.current().add(notificationRequest) { (error) in
                    if let error = error {
                        print("Unable to Add Notification Request (\(error), \(error.localizedDescription))")
                    }
                }
            }
        }
    }
    
    private func refreshSpeedInStatusBar() {
        let statusBar = NSStatusBar.system
        
        self.dataController.loadTrainStatus(demoMode: demoMode) { status, error in
            if let status = status {
                self.currentSpeedStatusItem = statusBar.statusItem(withLength: NSStatusItem.variableLength)
                self.currentSpeedStatusItem?.autosaveName = "current-speed"
                
                let speed = Measurement(value: status.speed, unit: UnitSpeed.kilometersPerHour)
                let formatter = MeasurementFormatter()
                self.currentSpeedStatusItem?.button?.title = formatter.string(from: speed)
                let speedMenu = NSMenu()

                
                let unpinItem = NSMenuItem(title: "Unpin from Menu Bar", action: #selector(self.toggleSpeedPin), keyEquivalent: "")
                unpinItem.target = self
                speedMenu.addItem(unpinItem)
                
                let infoItem = NSMenuItem(title: "(Automatically hides when not connected)", action: #selector(self.toggleSpeedPin), keyEquivalent: "")
                speedMenu.addItem(infoItem)
                
                self.currentSpeedStatusItem?.menu = speedMenu
            } else {
                if let currentSpeedStatusItem = self.currentSpeedStatusItem {
                    statusBar.removeStatusItem(currentSpeedStatusItem)
                }
            }
        }
    }
    
    var refreshAusstiegsAlarmMenuNextTime = false
    private func refreshAusstiegsalarmMenu(stops: [TrainStop]) {
        refreshAusstiegsAlarmMenuNextTime = false
        let submenu = NSMenu()
        let explaination = NSMenuItem(title: "Get reminded 10 mins before you reach your stop", action: nil, keyEquivalent: "")
        submenu.addItem(explaination)
        submenu.addItem(NSMenuItem.separator())
        
        let availableStopsToSelect = stops.map { stop -> NSMenuItem in
            let menuItem = NSMenuItem(title: stop.trainStation.name, action: #selector(didSelectStop), keyEquivalent: "")
            if let actualArrivalTime = stop.actualArrival {
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
        MenuBarController.ausstiegsAlarmStation = sender.title
        refreshAusstiegsAlarmMenuNextTime = true
        self.refreshAusstiegsAlarmNotification()
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
            SKStoreReviewController.requestReview()
        }
    }
    
    func refreshMenuBarItems() {
        
        self.refreshSpeedMenuItem()
        let statusBar = NSStatusBar.system
        
        iceStatusItem = statusBar.statusItem(withLength: NSStatusItem.squareLength)
        iceStatusItem?.autosaveName = "ice-buddy"
        
        

        iceStatusItem?.button?.image = NSImage(named: "menu bar icon")
        
        launchAtLoginMenuItem.action = #selector(toggleLaunchAtLogin)
        launchAtLoginMenuItem.target = self
        
        openLoginMenuItem.action = #selector(openWifiLogin)
        openLoginMenuItem.target = self
        
        twitterMenuItem.action = #selector(hmuTwitter)
        twitterMenuItem.target = self
        
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
        var pinSpeedButtonTitle = "Pin current speed to Menu Bar"
        if isSpeedPinned {
            pinSpeedButtonTitle = "Un-pin current speed to Menu Bar"
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
        if self.isSpeedPinned {
            SKStoreReviewController.requestReview()
        }
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
    
    
    let disconnectedMenuItem = NSMenuItem(title: "Please connect to WiFionICE / Wifi@DB", action: nil, keyEquivalent: "")
    let openLoginMenuItem = NSMenuItem(title: "Open LogIn.WIFIonICE.de in Safari", action: nil, keyEquivalent: "")
    
    let disconnectedLaunchAtLoginMenuItem = NSMenuItem(title: "Launch at Login", action: nil, keyEquivalent: "")
    let disconnectedTwitterMenuItem = NSMenuItem(title: "Questions? → Hit me up on Twitter!", action: nil, keyEquivalent: "")
    let disconnectedqQitMenuItem = NSMenuItem(title: "Quit ICE Buddy", action: nil, keyEquivalent: "")
    let disconnectedAboutMenuItem = NSMenuItem(title: "About", action: nil, keyEquivalent: "")
    
    var isConnected = true
    private func showDisconnectedMenu() {
        isConnected = false
        
        disconnectedLaunchAtLoginMenuItem.action = #selector(toggleLaunchAtLogin)
        disconnectedLaunchAtLoginMenuItem.target = self
        
        disconnectedTwitterMenuItem.action = #selector(hmuTwitter)
        disconnectedTwitterMenuItem.target = self
        
        disconnectedAboutMenuItem.action = #selector(showAbout)
        disconnectedAboutMenuItem.target = self
        
        disconnectedqQitMenuItem.action = #selector(quitApp)
        disconnectedqQitMenuItem.target = self
        
        disconnectedMenu.removeAllItems()
        disconnectedMenu.delegate = self
        disconnectedMenu.addItem(disconnectedMenuItem)
        self.disconnectedMenu.addItem(NSMenuItem.separator())
        self.disconnectedMenu.addItem(disconnectedAboutMenuItem)
        self.disconnectedMenu.addItem(disconnectedLaunchAtLoginMenuItem)
        self.disconnectedMenu.addItem(disconnectedTwitterMenuItem)
        self.disconnectedMenu.addItem(disconnectedqQitMenuItem)
        self.disconnectedMenu.update()
        self.iceStatusItem?.menu = disconnectedMenu
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
        
        self.dataController.loadTrainStatus(demoMode: demoMode) { status, error in
            if let status = status {
                
                let speed = Measurement(value: status.speed, unit: UnitSpeed.kilometersPerHour)
                let formatter = MeasurementFormatter()
                let speedString = formatter.string(from: speed)
                self.currentSpeedMenuItem.title = speedString
                self.currentSpeedStatusItem?.button?.title = speedString
                
                self.trainTypeMenuItem.title = "Train Model: \(status.trainType.trainModel)"
                
                if let internetQuality = status.currentConnectivity {
                    let devices: String
                    if let connectedDevices = status.connectedDevices {
                        devices = " (\(connectedDevices) devices connected)"
                    } else {
                        devices = ""
                    }
                    self.internetQualityMenuitem.title = "Internet Quality: \(internetQuality)" + devices
                } else {
                    self.internetQualityMenuitem.title = "Internet Quality: Unknown"
                }
                
             
                
                self.lastUpdateMenuitem.title = "Updated Infos: \(Date().humanReadableDateAndTimeString)"
                
                self.iceHeaderVC.imageView.image = status.trainType.trainIcon
                self.iceStatusItem?.menu = self.menu
            } else {
                self.showDisconnectedMenu()
            }
        }
        
        self.dataController.loadTrip(demoMode: demoMode) { trip, error in
            if let tripData = trip {
                self.mapVC.stops = tripData.trainStops
                if let origin = tripData.trainStops.first, let destination = tripData.trainStops.last {
                    self.connectionMenuItem.title = "\(tripData.train) \(tripData.vzn): \(origin.trainStation.name) → \(destination.trainStation.name)"
                }
                    
                
                
                if self.refreshAusstiegsAlarmMenuNextTime {
                    self.refreshAusstiegsalarmMenu(stops: tripData.trainStops)
                }
                
                if let nextStop = tripData.trainStops.nextStop {
                    if let humanReadableArrivalTime = nextStop.actualArrival?.minuteTimeString {
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
            } else {
                self.showDisconnectedMenu()
            }
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
