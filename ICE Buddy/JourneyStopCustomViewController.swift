//
//  JourneyStopCustomViewController.swift
//  ICE Buddy
//
//  Created by Frederik Riedel on 17.11.21.
//

import Cocoa
import DBConnect

class JourneyStopCustomViewController: NSViewController {
    
    @IBOutlet weak var topSegmentImageView: NSImageView!
    @IBOutlet weak var bottomSegmentImageView: NSImageView!
    @IBOutlet weak var mainSegmentImageView: NSImageView!
    
    @IBOutlet weak var ausstiegsAlarmIcon: NSImageView!
    @IBOutlet weak var stopNameLabel: NSTextField!
    @IBOutlet weak var arriveTimeLabel: NSTextField!
    @IBOutlet weak var trackLabel: NSTextField!
    @IBOutlet weak var delayLabel: NSTextField!
    
    init(stopIndex: Int, journey: Trip) {
        self.stopIndex = stopIndex
        self.journey = journey
        super.init(nibName: "JourneyStopCustomViewController", bundle: Bundle.main)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

    var stopIndex: Int
    var journey: Trip {
        didSet {
            self.reloadUI()
        }
    }
    
    private func reloadUI() {
        let stop = journey.stops[stopIndex]
        
        if stop.info.passed {
            self.stopNameLabel.textColor = NSColor.tertiaryLabelColor
            self.topSegmentImageView.image = NSImage(named: "stop_badge_grey")
            self.bottomSegmentImageView.image = NSImage(named: "stop_badge_grey")
            self.mainSegmentImageView.image = NSImage(named: "stop_icon_grey")
        } else {
            self.stopNameLabel.textColor = NSColor.labelColor
            self.topSegmentImageView.image = NSImage(named: "stop_badge")
            self.bottomSegmentImageView.image = NSImage(named: "stop_badge")
            self.mainSegmentImageView.image = NSImage(named: "stop_icon")
        }
        
        if stop.timetable.departureDelay == "" {
            self.delayLabel.isHidden = true
        } else {
            self.delayLabel.isHidden = false
            self.delayLabel.stringValue = stop.timetable.departureDelay
        }
        
        if stop.station.name == MenuBarController.ausstiegsAlarmStation {
            ausstiegsAlarmIcon.isHidden = false
        } else {
            ausstiegsAlarmIcon.isHidden = true
        }
        
        self.stopNameLabel.stringValue = stop.station.name
        self.trackLabel.stringValue = "Gleis \(stop.track.actual)"
        
        self.arriveTimeLabel.stringValue = stop.timetable.actualArrivalTimeDate?.minuteTimeString ?? "–"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.reloadUI()
        // Do view setup here.
    }
    
}
