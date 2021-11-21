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

enum TrainType: CaseIterable {
    
    case BR401, BR402, BR403, BR406, BR407, BR408, BR411, BR415, BR412, unknown
    
    private var triebZugNummern: [Int] {
        switch self {
        case .BR401:
            return [Int](101...199)
        case .BR402:
            return [Int](201...299)
        case .BR403:
            return [Int](301...399)
        case .BR406:
            return [Int](4601...4699)
        case .BR407:
            return [Int](701...799) + [Int](4701...4799)
        case .BR408:
            return [Int](801...899)
        case .BR411:
            return [Int](1101...1199)
        case .BR415:
            return [Int](1501...1599)
        case .BR412:
            return [Int](9001...9999)
        case .unknown:
            return []
        }
    }
    
    var humanReadableTrainType: String {
        switch self {
        case .BR401:
            return "ICE 1"
        case .BR402:
            return "ICE 2"
        case .BR403, .BR406, .BR407:
            return "ICE 3"
        case .BR408:
            return "ICE 3 Neo"
        case .BR411, .BR415:
            return "ICE T"
        case .BR412:
            return "ICE 4"
        case .unknown:
            return "Unknown Train Type"
        }
    }
    
    
    public static func trainType(from triebZugNummer: String) -> TrainType {
        return TrainType.allCases.first { trainType in
            trainType.triebZugNummern.contains(triebzugnummer: triebZugNummer)
        } ?? .unknown
    }
    
    var trainIcon: NSImage {
        switch self {
        case .BR401:
            return NSImage(named: "BR401")!
        case .BR402:
            return NSImage(named: "BR402")!
        case .BR403:
            return NSImage(named: "BR403")!
        case .BR406:
            return NSImage(named: "BR406")!
        case .BR407:
            return NSImage(named: "BR407")!
        case .BR408:
            return NSImage(named: "BR408")!
        case .BR411:
            return NSImage(named: "BR411")!
        case .BR415:
            return NSImage(named: "BR415")!
        case .BR412:
            return NSImage(named: "BR412")!
        case .unknown:
            return NSImage(named: "BR401")!
        }
    }
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
    
    let coordinate: CLLocationCoordinate2D
    
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
            
            if let geocoordinates = station["geocoordinates"] as? [String: Double] {
                if let latitude = geocoordinates["latitude"], let longitude = geocoordinates["longitude"] {
                    self.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                } else {
                    return nil
                }
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
