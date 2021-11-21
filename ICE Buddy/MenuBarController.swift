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
import FredKitAnalytics

class MenuBarController: NSObject {
    
    static let shared = MenuBarController()
    
    private var iceStatusItem: NSStatusItem?
    
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
    
    func refreshMenuBarItem() {
        let statusBar = NSStatusBar.system
        iceStatusItem = statusBar.statusItem(withLength: NSStatusItem.squareLength)
        iceStatusItem?.autosaveName = "ice-buddy"
        
        iceStatusItem?.button?.image = NSImage(systemSymbolName: "tram.fill", accessibilityDescription: "ice train")

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
        
        self.refreshMenuBarMenu()
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
    private func refreshMenuBarMenu() {
        
        menu.removeAllItems()
        self.journeyViewControllers.removeAll()
        
        
        
        
        menu.delegate = self
        iceStatusItem?.menu = menu;
        
        self.menu.addItem(iceHeaderMenuItem)
        self.menu.addItem(NSMenuItem.separator())
        self.menu.addItem(connectionMenuItem)
        self.menu.addItem(currentSpeedMenuItem)
        self.menu.addItem(trainTypeMenuItem)
        self.menu.addItem(NSMenuItem.separator())
        // connection stops dynamically added inbetween
        self.menu.addItem(showMapMenuItem)
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
    
    
    let disconnectedMenuItem = NSMenuItem(title: "Please connect to WiFionICE", action: nil, keyEquivalent: "")
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
//        disconnectedMenu.addItem(openLoginMenuItem)
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
        
        ICEConnection.shared.loadCurrentTrainData { metaData in
            
#if DEBUG
            if self.debugCounter%2==1 {
                self.showDisconnectedMenu()
                return
            }
#endif
            
            if let metaData = metaData {
                let speed = Measurement(value: metaData.speed, unit: UnitSpeed.kilometersPerHour)
                let formatter = MeasurementFormatter()
                self.currentSpeedMenuItem.title = formatter.string(from: speed)
                self.trainTypeMenuItem.title = "Train Model: \(metaData.trainType.humanReadableTrainType)"
                #if DEBUG
                self.lastUpdateMenuitem.title = "Updated Infos: Just now"
                #else
                self.lastUpdateMenuitem.title = "Updated Infos: \(metaData.timestamp.humanReadableDateAndTimeString)"
                #endif
                
                self.iceHeaderVC.imageView.image = metaData.trainType.trainIcon
                self.iceStatusItem?.menu = self.menu
            } else {
                self.showDisconnectedMenu()
            }
        }
        
        ICEConnection.shared.loadCurrentTripData { tripData in
            
#if DEBUG
            if self.debugCounter%2==1 {
                self.showDisconnectedMenu()
                return
            }
#endif
            
            if let tripData = tripData, let origin = tripData.startStop, let destination = tripData.finalStop {
                self.mapVC.stops = tripData.stops
                self.connectionMenuItem.title = "\(tripData.trainId): \(origin.name) → \(destination.name)"
                
                if let nextStop = tripData.nextStop {
                    self.nextStopValueMenuItem.title = "\(nextStop.humanReadableArrivalTime), \(nextStop.name)"
                    self.nextStopTrackMenuItem.title = "Track: \(nextStop.actualTrack)"
                }
                
                if self.journeyViewControllers.isEmpty {
                    self.journeyViewControllers = tripData.stops.enumerated().map({ enumeration in
                        return JourneyStopCustomViewController(stopIndex: enumeration.offset, journey: tripData)
                    })
                    
                    self.journeyViewControllers.enumerated().forEach { enumeration in
                        let index = 6 + enumeration.offset
                        let stopMenuItem = NSMenuItem()
                        stopMenuItem.view = enumeration.element.view
                        self.menu.insertItem(stopMenuItem, at: index)
                    }
                } else if tripData.stops.count != self.journeyViewControllers.count {
                    self.journeyViewControllers.removeAll()
                    self.refreshMenuBarMenu()
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
            self.refreshMenuBarMenu()
            self.isConnected = true
        } else {
            self.refreshMetaData()
        }
        
        FredKitAnalytics.trackViewController(viewControllerIds: ["Overview"])
        
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
