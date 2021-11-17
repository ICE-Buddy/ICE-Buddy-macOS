//
//  MenuBarController.swift
//  ICE Buddy
//
//  Created by Frederik Riedel on 16.11.21.
//

import Foundation
import AppKit

class MenuBarController: NSObject {
    
    static let shared = MenuBarController()
    
    private var iceStatusItem: NSStatusItem?
    
    let iceHeaderMenuItem = NSMenuItem()
    
    
    let iceBuddyHeaderMenuItem = NSMenuItem(title: "ICE Buddy", action: nil, keyEquivalent: "")
    let lastUpdateMenuitem = NSMenuItem(title: "Updated: Just now", action: nil, keyEquivalent: "")
    
    let currentSpeedMenuItem = NSMenuItem(title: "– km/h", action: nil, keyEquivalent: "")
    let trainTypeMenuItem = NSMenuItem(title: "–", action: nil, keyEquivalent: "")
    
    let connectionMenuItem = NSMenuItem(title: "– → –", action: nil, keyEquivalent: "")
    let nextStopTitleMenuItem = NSMenuItem(title: "Next Stop:", action: nil, keyEquivalent: "")
    let nextStopValueMenuItem = NSMenuItem(title: "–, –:–", action: nil, keyEquivalent: "")
    let nextStopTrackMenuItem = NSMenuItem(title: "Track: –", action: nil, keyEquivalent: "")
    
    
    let aboutMenuItem = NSMenuItem(title: "About", action: nil, keyEquivalent: "")
    let settingsMenuItem = NSMenuItem(title: "Settings", action: nil, keyEquivalent: "")
    let quitMenuItem = NSMenuItem(title: "Quit", action: nil, keyEquivalent: "")
    
    let menu = NSMenu(title: "ICE Buddy")
    
    var continousUpdateTimer: Timer?
    
    func refreshMenuBarItem() {
        
        let statusBar = NSStatusBar.system
        iceStatusItem = statusBar.statusItem(withLength: NSStatusItem.squareLength)
        iceStatusItem?.autosaveName = "ice-buddy"
        
        iceStatusItem?.button?.image = NSImage(systemSymbolName: "tram.fill", accessibilityDescription: "ice train")

        
        let iceHeaderVC = ICEHeader()
        iceHeaderMenuItem.view = iceHeaderVC.view
        
        menu.delegate = self
        iceStatusItem?.menu = menu;
        
        self.menu.addItem(iceHeaderMenuItem)
        self.menu.addItem(NSMenuItem.separator())
        self.menu.addItem(connectionMenuItem)
        self.menu.addItem(nextStopTitleMenuItem)
        self.menu.addItem(nextStopValueMenuItem)
        self.menu.addItem(nextStopTrackMenuItem)
        self.menu.addItem(NSMenuItem.separator())
        self.menu.addItem(currentSpeedMenuItem)
        self.menu.addItem(trainTypeMenuItem)
        self.menu.addItem(NSMenuItem.separator())
        self.menu.addItem(iceBuddyHeaderMenuItem)
        self.menu.addItem(lastUpdateMenuitem)
        self.menu.addItem(NSMenuItem.separator())
        self.menu.addItem(aboutMenuItem)
        self.menu.addItem(settingsMenuItem)
        self.menu.addItem(quitMenuItem)
        
        
        aboutMenuItem.action = #selector(showAbout)
        aboutMenuItem.target = self
        
        quitMenuItem.action = #selector(quitApp)
        quitMenuItem.target = self

        settingsMenuItem.submenu = NSMenu(title: "Settings")
        
        self.refreshMetaData()
    }
    
    @objc func showAbout() {
        
    }
    
    @objc func quitApp() {
        NSApp.terminate(nil)
    }
    
    @objc func refreshMetaData() {
        ICEConnection.shared.loadCurrentTrainData { metaData in
            if let metaData = metaData {
                self.currentSpeedMenuItem.title = "\(metaData.speed) km/h"
                self.trainTypeMenuItem.title = "Train Model: \(metaData.trainType.humanReadableTrainType)"
                self.lastUpdateMenuitem.title = "Updated: Just now"
            } else {
                
            }
        }
        
        ICEConnection.shared.loadCurrentTripData { tripData in
            if let tripData = tripData, let origin = tripData.startStop, let destination = tripData.finalStop {
                self.connectionMenuItem.title = "\(tripData.trainId): \(origin.name) → \(destination.name)"
                
                if let nextStop = tripData.nextStop {
                    self.nextStopValueMenuItem.title = "\(nextStop.humanReadableArrivalTime), \(nextStop.name)"
                    self.nextStopTrackMenuItem.title = "Track: \(nextStop.actualTrack)"
                }
            }
            
        }
    }
    
}

extension MenuBarController: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        self.refreshMetaData()
        
        continousUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { _ in
            self.refreshMetaData()
        })
        
        RunLoop.main.add(continousUpdateTimer!, forMode: .common)
    }
    
    func menuDidClose(_ menu: NSMenu) {
        continousUpdateTimer?.invalidate()
    }
}
