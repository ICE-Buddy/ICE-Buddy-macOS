//
//  JourneyMapViewController.swift
//  ICE Buddy
//
//  Created by Frederik Riedel on 21.11.21.
//

import Cocoa
import MapKit
import DBConnect
import TrainConnect

class JourneyMapViewController: NSViewController {

    @IBOutlet weak var mapView: MKMapView!
    
    var stops: [TrainStop] = [] {
        didSet {
            mapView.removeOverlays(mapView.overlays)
            let coordinates = stops.compactMap { stop in
                return stop.trainStation.coordinates
            }
            let polyLine = MKPolyline(coordinates: coordinates, count: coordinates.count)
            mapView.addOverlay(polyLine)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        // Do view setup here.
    }
    
}

extension JourneyMapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = .init(red: 1, green: 0, blue: 0, alpha: 0.9)
        renderer.lineWidth = 3
        return renderer
    }
}
