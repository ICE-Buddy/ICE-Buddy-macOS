//
//  ICEConnection.swift
//  ICE Buddy
//
//  Created by Frederik Riedel on 16.11.21.
//

import Foundation
import Alamofire
import CoreLocation
import FredKit
import AppKit

enum InternetConnection {
    case high, unstable
    
    static func from(rawString: String) -> InternetConnection {
        if rawString == "HIGH" {
            return .high
        }
        return .unstable
    }
}

enum TrainType {
    
    case ice1, ice2, ice3, ice4, unknown
    
    // tz 101 to tz 190
    private static var ice1Numbers: [Int] {
        return [Int](101...199)
    }
    
    private static var ice2Numbers: [Int] {
        return [Int](201...299)
    }
    
    private static var ice3Numbers: [Int] {
        return [Int](301...399) + [Int](701...799) + [Int](4601...4699)
    }
    
    private static var ice4Numbers: [Int] {
        return [Int](9001...9999)
    }
    
    public static func trainType(from triebZugNummer: String) -> TrainType {
        if ice1Numbers.contains(triebzugnummer: triebZugNummer) {
            return .ice1
        }
        
        if ice2Numbers.contains(triebzugnummer: triebZugNummer) {
            return .ice2
        }
        
        if ice3Numbers.contains(triebzugnummer: triebZugNummer) {
            return .ice3
        }
        
        if ice4Numbers.contains(triebzugnummer: triebZugNummer) {
            return .ice4
        }
        
        return .unknown
    }
    
    var humanReadableTrainType: String {
        switch self {
        case .ice1:
            return "ICE 1"
        case .ice2:
            return "ICE 2"
        case .ice3:
            return "ICE 3"
        case .ice4:
            return "ICE 4"
        case .unknown:
            return "Unknown Train Type"
        }
    }
    
    var trainIcon: NSImage {
        switch self {
        case .ice1:
            return NSImage(named: "ice 1")!
        case .ice2:
            return NSImage(named: "ice 2")!
        case .ice3:
            return NSImage(named: "ice 3")!
        case .ice4:
            return NSImage(named: "ice 4")!
        case .unknown:
            return NSImage(named: "ice 1")!
        }
    }
    
    //    var icon: String {
    //
    //    }
}

struct ICEMetaData {
    let speed: Double
    let internetConnection: InternetConnection
    let trainType: TrainType
    let currentLocation: CLLocationCoordinate2D
    let timestamp: Date
    
    init?(dict: [String: Any]) {
        
        if let speed = dict["speed"] as? Double {
            self.speed = speed
        } else {
            return nil
        }
        
        if let internetConnectivity = dict["connectivity"] as? [String: Any] {
            if let currentState = internetConnectivity["currentState"] as? String {
                self.internetConnection = InternetConnection.from(rawString: currentState)
            } else {
                return nil
            }
        } else {
            return nil
        }
        
        if let triebZugNummer = dict["tzn"] as? String {
            self.trainType = TrainType.trainType(from: triebZugNummer)
        } else {
            return nil
        }
        
        if let longitude = dict["longitude"] as? Double, let latitude = dict["latitude"] as? Double {
            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            self.currentLocation = coordinate
        } else {
            return nil
        }
        
        if let serverTime = dict["serverTime"] as? Double {
            self.timestamp = Date(timeIntervalSince1970: serverTime / 1000)
        } else {
            return nil
        }
    }
}

struct Stop {
    let evaNr: String
    let name: String
    
    let actualDepartureTime: Date?
    let actualArrivalTime: Date?
    
    let scheduledDepartureTime: Date?
    let scheduledArrivalTime: Date?
    
    let departureDelay: String
    let scheduledTrack: String
    let actualTrack: String
    
    let passed: Bool
    
    var humanReadableArrivalTime: String {
        if let actualArrivalTime = actualArrivalTime {
            return actualArrivalTime.minuteTimeString
        }
        
        if let scheduledArrivalTime = scheduledArrivalTime {
            return scheduledArrivalTime.minuteTimeString
        }
        
        if let actualDepartureTime = actualDepartureTime {
            return actualDepartureTime.minuteTimeString
        }
        
        if let scheduledDepartureTime = scheduledDepartureTime {
            return scheduledDepartureTime.minuteTimeString
        }
        
        
        return "Time Unknown"
    }
    
    init?(dict: [String: Any]) {
        if let station = dict["station"] as? [String: Any] {
            
            if let evaNr = station["evaNr"] as? String {
                self.evaNr = evaNr
            } else {
                return nil
            }
            
            if let stopName = station["name"] as? String {
                self.name = stopName
            } else {
                return nil
            }
            
        } else {
            return nil
        }
        
        if let info = dict["info"] as? [String: Any] {
            if let passed = info["passed"] as? Bool {
                self.passed = passed
            } else {
                return nil
            }
        } else {
            return nil
        }
        
        if let track = dict["track"] as? [String: Any] {
            
            if let actualTrack = track["actual"] as? String {
                self.actualTrack = actualTrack
            } else {
                return nil
            }
            
            if let scheduledTrack = track["scheduled"] as? String {
                self.scheduledTrack = scheduledTrack
            } else {
                return nil
            }
            
        } else {
            return nil
        }
        
        if let timetable = dict["timetable"] as? [String: Any] {
            if let actualDepartureTime = timetable["actualDepartureTime"] as? Double {
                self.actualDepartureTime = Date(timeIntervalSince1970: actualDepartureTime / 1000.0)
            } else {
                self.actualDepartureTime = nil
            }
            
            if let actualArrivalTime = timetable["actualArrivalTime"] as? Double {
                self.actualArrivalTime = Date(timeIntervalSince1970: actualArrivalTime / 1000.0)
            } else {
                self.actualArrivalTime = nil
            }
            
            if let scheduledArrivalTime = timetable["scheduledArrivalTime"] as? Double {
                self.scheduledArrivalTime = Date(timeIntervalSince1970: scheduledArrivalTime / 1000.0)
            } else {
                self.scheduledArrivalTime = nil
            }
            
            if let scheduledDepartureTime = timetable["scheduledDepartureTime"] as? Double {
                self.scheduledDepartureTime = Date(timeIntervalSince1970: scheduledDepartureTime / 1000.0)
            } else {
                self.scheduledDepartureTime = nil
            }
            
            if let departureDelay = timetable["departureDelay"] as? String {
                self.departureDelay = departureDelay
            } else {
                return nil
            }
            
        } else {
            return nil
        }
    }
}

struct TrainTripData {
    let trainId: String
    let stops: [Stop]
    
    var startStop: Stop? {
        return stops.first
    }
    
    var finalStop: Stop? {
        return stops.last
    }
    
    var nextStop: Stop? {
        stops.first { stop in
            !stop.passed
        }
    }
    
    
    
    init?(dict: [String: Any]) {
        if let tripDict = dict["trip"] as? [String: Any] {
            if let trainType = tripDict["trainType"] as? String, let connectionId = tripDict["vzn"] as? String {
                self.trainId = "\(trainType) \(connectionId)"
            } else {
                return nil
            }
            
            if let stops = tripDict["stops"] as? [ [String: Any] ] {
                self.stops = stops.compactMap({ stopDict in
                    return Stop(dict: stopDict)
                })
            } else {
                return nil
            }
            
            
            
        } else {
            return nil
        }
    }
}

class ICEConnection {
    
    static let shared = ICEConnection()
    
    func loadCurrentTrainData(completion: @escaping (ICEMetaData?) -> Void) {
        AF.request("https://iceportal.de/api1/rs/status").responseJSON { response in
            if let result = response.value as? [String: Any] {
                let metaData = ICEMetaData(dict: result)
                completion(metaData)
            } else {
#if DEBUG
                if let data = try? Data(contentsOf: Bundle.main.url(forResource: "status", withExtension: "json")!) {
                    let jsonResult = try? JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
                    if let jsonResult = jsonResult as? [String: Any] {
                        let metaData = ICEMetaData(dict: jsonResult)
                        completion(metaData)
                    }
                }
#else
                // currently not connected to ICE?
                completion(nil)
#endif
            }
        }
    }
    
    func loadCurrentTripData(completion: @escaping (TrainTripData?) -> Void) {
        AF.request("https://iceportal.de/api1/rs/tripInfo/trip").responseJSON { response in
            if let result = response.value as? [String: Any] {
                let metaData = TrainTripData(dict: result)
                completion(metaData)
            } else {
#if DEBUG
                let random = Int.random(in: 1...1)
                
                if random == 2 {
                    completion(nil)
                    return
                }
                
                if let data = try? Data(contentsOf: Bundle.main.url(forResource: "tripInfo\(random)", withExtension: "json")!) {
                    let jsonResult = try? JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
                    if let jsonResult = jsonResult as? [String: Any] {
                        let metaData = TrainTripData(dict: jsonResult)
                        completion(metaData)
                    }
                }
#else
                // currently not connected to ICE?
                completion(nil)
#endif
            }
        }
    }
    
}

extension Array where Element == Int {
    private func number(number: Int, matchesWithTzn tzn: String) -> Bool {
        tzn.lowercased() == "tz\(number)" || tzn.lowercased() == "tz \(number)"
    }
    
    func contains(triebzugnummer: String) -> Bool {
        self.contains(where: { number in
            self.number(number: number, matchesWithTzn: triebzugnummer)
        })
    }
}
