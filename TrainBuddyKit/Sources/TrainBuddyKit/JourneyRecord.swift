import Foundation
import TrainConnect

/// Values shared with the widget process. Never persist raw portal responses or coordinates.
public struct TrainJourney: Codable, Equatable, Sendable {
    public let serviceName: String
    public let vehicleModel: String?
    public let destination: String
    public let stops: [JourneyStop]
    public let speedKilometersPerHour: Int?
    public let fetchedAt: Date
    public let isDemo: Bool
    public let artworkPNG: Data?

    public var nextStop: JourneyStop? { stops.first { !$0.hasPassed && !$0.isCancelled } }

    public init(snapshot: TrainSnapshot, isDemo: Bool, artworkPNG: Data? = nil) {
        serviceName = snapshot.trip.serviceName
        vehicleModel = snapshot.trainType?.trainModel
        destination = snapshot.trip.finalStopInfo?.finalStationName ?? snapshot.trip.trainStops.last?.trainStation.name ?? ""
        stops = snapshot.trip.trainStops.map(JourneyStop.init)
        let speed = snapshot.status?.currentSpeed.converted(to: .kilometersPerHour).value
        speedKilometersPerHour = speed.flatMap { $0.isFinite && $0 >= 0 && $0 < 1000 ? Int($0.rounded()) : nil }
        fetchedAt = snapshot.fetchedAt
        self.isDemo = isDemo
        self.artworkPNG = artworkPNG
    }
}

public struct JourneyStop: Codable, Equatable, Sendable, Identifiable {
    public let id: UUID
    public let station: String
    public let scheduledArrival: Date?
    public let actualArrival: Date?
    public let scheduledDeparture: Date?
    public let actualDeparture: Date?
    public let arrivalDelay: String
    public let departureDelay: String
    public let scheduledPlatform: String?
    public let platform: String?
    public let hasPassed: Bool
    public let isCancelled: Bool
    public let delayReason: String?

    init(_ stop: any TrainStop) {
        id = stop.id
        station = stop.trainStation.name
        scheduledArrival = stop.scheduledArrival
        actualArrival = stop.actualArrival
        scheduledDeparture = stop.scheduledDeparture
        actualDeparture = stop.actualDeparture
        arrivalDelay = stop.arrivalDelay
        departureDelay = stop.departureDelay
        scheduledPlatform = stop.trainTrack?.scheduled.nilIfEmpty
        platform = stop.trainTrack?.actual.nilIfEmpty ?? scheduledPlatform
        hasPassed = stop.hasPassed
        isCancelled = stop.isCancelled
        delayReason = stop.delayReason
    }
}

public struct JourneyRecord: Codable, Equatable, Sendable {
    public private(set) var journey: TrainJourney?
    public private(set) var lastAttempt: Date?
    public private(set) var refreshFailed: Bool

    public static let empty = JourneyRecord(journey: nil, lastAttempt: nil, refreshFailed: false)

    public func isStale(at date: Date) -> Bool {
        guard let journey else { return true }
        return refreshFailed || date.timeIntervalSince(journey.fetchedAt) >= 60
    }

    public func receiving(_ journey: TrainJourney) -> Self {
        Self(journey: journey, lastAttempt: journey.fetchedAt, refreshFailed: false)
    }

    /// A failed request must never give old journey data a new freshness timestamp.
    public func failing(at date: Date) -> Self {
        Self(journey: journey, lastAttempt: date, refreshFailed: true)
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
