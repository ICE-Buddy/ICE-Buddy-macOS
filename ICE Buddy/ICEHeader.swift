//
//  ICEHeader.swift
//  ICE Buddy
//
//  Created by Frederik Riedel on 16.11.21.
//

import Cocoa

class ICEHeader: NSViewController {

    @IBOutlet weak var imageView: NSImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.imageView.layer?.minificationFilter = .trilinear
        // Do view setup here.
    }
    
}
