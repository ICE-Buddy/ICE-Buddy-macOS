//
//  SharingMenuitem.swift
//  ICE Buddy
//
//  Created by Frederik Riedel on 21.11.21.
//

import Foundation
import AppKit

extension NSSharingServicePicker {
    
    class func menu(forSharingItems items: [AnyHashable]) -> NSMenu? {
        
        let sharingServices = NSSharingService.sharingServices(forItems: items)
        
        if sharingServices.isEmpty {
            return nil
        }
        
        let menu = NSMenu()
        
        for service in sharingServices {
            
            let item = SharingMenuItem(label: service.title, action: #selector(_openSharingService), target: self, userInfo: ["sharingItems": items])
            
            item.image = service.image
            item.representedObject = service
            item.target = self
            menu.addItem(item)
        }
        
        return menu
        
    }
    
    @objc class private func _openSharingService(sender: SharingMenuItem) {
        
        guard let items = sender.userInfo["sharingItems"] as? [AnyHashable], let service = sender.representedObject as? NSSharingService else {
            return
        }
        
        service.perform(withItems: items)
        
    }
    
}

class SharingMenuItem: NSMenuItem {
    
    var userInfo: [String : Any] = [:]
    
    init(label: String, action: Selector?, target: AnyObject?, userInfo: [String : Any]) {
        self.userInfo = userInfo
        super.init(title: label, action: action, keyEquivalent: "")
    }
    
    required init(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }
    
}
