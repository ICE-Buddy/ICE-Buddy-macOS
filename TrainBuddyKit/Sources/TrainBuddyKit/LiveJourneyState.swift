import Foundation

/// A small ActivityKit payload: never include the complete journey or its artwork.
public struct LiveJourneyState: Codable, Hashable, Sendable {
    public let serviceName: String
    public let destination: String
    public let nextStation: String
    public let scheduledArrival: Date?
    public let actualArrival: Date?
    public let delay: String
    public let platform: String?
    public let speedKilometersPerHour: Int?
    public let fetchedAt: Date?
    public let isDemo: Bool
    public let refreshFailed: Bool
    public let isRefreshing: Bool

    public init(record: JourneyRecord, isRefreshing: Bool = false, isDemo: Bool = false) {
        let journey = record.journey
        let stop = journey?.nextStop
        serviceName = Self.bounded(journey?.serviceName ?? "Train Buddy", bytes: 160)
        destination = Self.bounded(journey?.destination ?? "", bytes: 240)
        nextStation = Self.bounded(stop?.station ?? "", bytes: 240)
        scheduledArrival = stop?.scheduledArrival ?? stop?.scheduledDeparture
        actualArrival = stop?.actualArrival ?? stop?.actualDeparture
        delay = Self.bounded(stop?.scheduledArrival != nil ? stop?.arrivalDelay ?? "" : stop?.departureDelay ?? "", bytes: 32)
        platform = stop?.platform.map { Self.bounded($0, bytes: 32) }
        speedKilometersPerHour = journey?.speedKilometersPerHour
        fetchedAt = journey?.fetchedAt
        self.isDemo = journey?.isDemo ?? isDemo
        refreshFailed = record.refreshFailed
        self.isRefreshing = isRefreshing
    }

    private static func bounded(_ value: String, bytes: Int) -> String {
        String(decoding: value.utf8.prefix(bytes), as: UTF8.self)
    }
}
