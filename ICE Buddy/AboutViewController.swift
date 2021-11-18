//
//  AboutViewController.swift
//  ICE Buddy
//
//  Created by Frederik Riedel on 17.11.21.
//

import Cocoa
import FredKit

class AboutViewController: NSViewController {

    @IBOutlet weak var titleLabel: NSTextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.stringValue = "ICE Buddy Version \(AppInfos.humanReadableVersionString)"
        // Do view setup here.
        
        self.title = "About"
    }
    
    @IBAction func showImprint(_ sender: Any) {
        let url = URL(string:"https://riedel.wtf/imprint/")!
        NSWorkspace.shared.open([url],
                                withAppBundleIdentifier:"com.apple.Safari",
                                options: [],
                                additionalEventParamDescriptor: nil,
                                launchIdentifiers: nil)
    }
    
    @IBAction func showPP(_ sender: Any) {
        let url = URL(string:"https://riedel.wtf/privacy/")!
        NSWorkspace.shared.open([url],
                                withAppBundleIdentifier:"com.apple.Safari",
                                options: [],
                                additionalEventParamDescriptor: nil,
                                launchIdentifiers: nil)
    }
    
}
