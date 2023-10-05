//
//  JourneyStopCustomViewController.swift
//  ICE Buddy
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
    @IBOutlet weak var actualTimeLabel: NSTextField!
    @IBOutlet weak var scheduledTimeLabel: NSTextField!
    @IBOutlet weak var trackLabel: NSTextField!
    
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
        let stop = journey.trainStops[stopIndex]
        
        let firstStop = stopIndex == 0
        let lastStop = stopIndex == journey.trainStops.count - 1
        
        if stop.hasPassed {
            self.stopNameLabel.textColor = NSColor.tertiaryLabelColor
            if !firstStop {
                self.topSegmentImageView.image = NSImage(named: "stop_badge_grey")
            } else {
                self.topSegmentImageView.image = nil
            }
            if !lastStop {
                self.bottomSegmentImageView.image = NSImage(named: "stop_badge_grey")
            } else {
                self.bottomSegmentImageView.image = nil
            }
            self.mainSegmentImageView.image = NSImage(named: "stop_icon_grey")
        } else {
            self.stopNameLabel.textColor = NSColor.labelColor
            if !firstStop {
                self.topSegmentImageView.image = NSImage(named: "stop_badge")
            } else {
                self.topSegmentImageView.image = nil
            }
            if !lastStop {
                self.bottomSegmentImageView.image = NSImage(named: "stop_badge")
            } else {
                self.bottomSegmentImageView.image = nil
            }
            self.mainSegmentImageView.image = NSImage(named: "stop_icon")
        }
        
        // past stops usually show no actual times
        let showActual = (stop.showActualTime ?? false) && !stop.hasPassed
        
        // will fallback to departure, if arrival is unavailable
        if showActual, let actualTime = stop.actualTime {
            self.actualTimeLabel.isHidden = false
            self.actualTimeLabel.stringValue = actualTime.minuteTimeString
            
            // Red for delays. Green for delays <= 5 minutes.
            if let scheduledTime = stop.scheduledTime {
                let diff = Int(actualTime.timeIntervalSince1970 - scheduledTime.timeIntervalSince1970)
                let hours = diff / 3600
                let minutes = (diff - hours * 3600) / 60
                self.actualTimeLabel.textColor = minutes <= 5 ? .systemGreen : .systemRed
            }
        } else {
            self.actualTimeLabel.isHidden = true
        }
        
        if stop.trainStation.name == MenuBarController.ausstiegsAlarmStation {
            ausstiegsAlarmIcon.isHidden = false
        } else {
            ausstiegsAlarmIcon.isHidden = true
        }
        
        self.stopNameLabel.stringValue = stop.trainStation.name
        if let trainTrack = stop.trainTrack {
            let track = trainTrack.actual
            self.trackLabel.stringValue = "Gl. \(track)"
            if trainTrack.actual == trainTrack.scheduled {
                trackLabel.textColor = .secondaryLabelColor
            } else {
                trackLabel.textColor = .systemRed
            }
        } else {
            self.trackLabel.stringValue = ""
        }
        
        // Will fallback to departure if arrival in unavailable:
        if let scheduledTime = stop.scheduledTime {
            self.scheduledTimeLabel.stringValue = scheduledTime.minuteTimeString
        } else {
            self.scheduledTimeLabel.stringValue = ""
        }
               
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.reloadUI()
        // Do view setup here.
    }
    
}
