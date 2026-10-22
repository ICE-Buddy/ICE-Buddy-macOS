//
//  JourneyStopCustomViewController.swift
//  Train Buddy
//
//  Created by Frederik Riedel on 17.11.21.
//

import Cocoa
import TrainConnect

class JourneyStopCustomViewController: NSViewController {
    
    @IBOutlet weak var topSegmentImageView: NSImageView!
    @IBOutlet weak var bottomSegmentImageView: NSImageView!
    @IBOutlet weak var mainSegmentImageView: NSImageView!
    
    @IBOutlet weak var ausstiegsAlarmIcon: NSImageView!
    @IBOutlet weak var stopNameLabel: NSTextField!
    @IBOutlet weak var arriveTimeLabel: NSTextField!
    @IBOutlet weak var trackLabel: NSTextField!
    @IBOutlet weak var delayLabel: NSTextField!
    
    init(stopIndex: Int, journey: TrainTrip) {
        self.stopIndex = stopIndex
        self.journey = journey
        super.init(nibName: "JourneyStopCustomViewController", bundle: Bundle.main)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

    var stopIndex: Int
    var journey: TrainTrip {
        didSet {
            self.reloadUI()
        }
    }
    
    private func reloadUI() {
        guard isViewLoaded, journey.trainStops.indices.contains(stopIndex) else { return }
        let stop = journey.trainStops[stopIndex]
        
        if stop.hasPassed {
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
        
        let delay = stop.departureDelay.isEmpty ? stop.arrivalDelay : stop.departureDelay
        if delay.isEmpty {
            self.delayLabel.isHidden = true
        } else {
            self.delayLabel.isHidden = false
            self.delayLabel.stringValue = delay
        }
        
        if stop.trainStation.name == MenuBarController.ausstiegsAlarmStation {
            ausstiegsAlarmIcon.isHidden = false
        } else {
            ausstiegsAlarmIcon.isHidden = true
        }
        
        self.stopNameLabel.stringValue = stop.trainStation.name + (stop.isCancelled ? " (" + NSLocalizedString("Cancelled", comment: "") + ")" : "")
        if let track = stop.trainTrack?.actual {
            self.trackLabel.stringValue = String(format: NSLocalizedString("Platform %@", comment: ""), track)
        } else {
            self.trackLabel.stringValue = ""
        }
        
        self.arriveTimeLabel.stringValue = (stop.actualArrival ?? stop.scheduledArrival ?? stop.actualDeparture ?? stop.scheduledDeparture)?.minuteTimeString ?? "–"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.reloadUI()
        // Do view setup here.
    }
    
}
