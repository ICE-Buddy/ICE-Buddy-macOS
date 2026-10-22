import Foundation
import CoreLocation
import Testing
import TrainConnect
@testable import TrainBuddyKit

struct JourneySharingTests {
    @Test func failedRefreshPreservesDataAndFreshnessAcrossProcesses() throws {
        let date = Date(timeIntervalSince1970: 1_800_000_000)
        let snapshot = TrainSnapshot(trip: FixtureTrip(stops: [FixtureStop()]), status: nil, fetchedAt: date)
        let loaded = JourneyRecord.empty.receiving(TrainJourney(snapshot: snapshot, isDemo: false))
        #expect(!loaded.isStale(at: date.addingTimeInterval(59)))
        #expect(loaded.isStale(at: date.addingTimeInterval(60)))
        let failed = loaded.failing(at: date.addingTimeInterval(10))
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        try JourneyStore(directory: directory).save(failed)
        let reopened = JourneyStore(directory: directory).read()
        let journey = try #require(reopened.journey)
        let nextStop = try #require(journey.nextStop)
        #expect(journey.fetchedAt == date)
        #expect(reopened.lastAttempt == date.addingTimeInterval(10))
        #expect(reopened.isStale(at: date.addingTimeInterval(10)))
        #expect(nextStop.arrivalDelay == "+1")
        #expect(nextStop.platform == "9")
        #expect(nextStop.scheduledPlatform == "8")
    }

    @Test func liveActivitySkipsCancelledStopsAndFitsThePlatformPayloadLimit() throws {
        var cancelled = FixtureStop()
        cancelled.isCancelled = true
        cancelled.trainStation = FixtureStation(name: "Cancelled station")
        var next = FixtureStop()
        // One grapheme can contain many UTF-8 bytes. Character-count limits are insufficient.
        next.trainStation = FixtureStation(name: "A" + String(repeating: "\u{0301}", count: 5000))
        let snapshot = TrainSnapshot(trip: FixtureTrip(stops: [cancelled, next]), status: nil)
        let record = JourneyRecord.empty.receiving(TrainJourney(snapshot: snapshot, isDemo: true,
            artworkPNG: Data(repeating: 255, count: 100_000)))
        let state = LiveJourneyState(record: record)
        let payload = try JSONEncoder().encode(state)
        #expect(payload.count < 4096)
        #expect(!state.nextStation.isEmpty)
        #expect(state.nextStation != "Cancelled station")
        #expect(state.delay == "+1")
        #expect(state.isDemo)
        #expect(state.fetchedAt == snapshot.fetchedAt)
        #expect(try JSONDecoder().decode(LiveJourneyState.self, from: payload) == state)
    }

    @Test func switchingDemoModeClearsSharedJourneyAndCorruptCacheHasNoData() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = JourneyStore(directory: directory)
        let snapshot = TrainSnapshot(trip: FixtureTrip(stops: [FixtureStop()]), status: nil)
        try store.save(.empty.receiving(TrainJourney(snapshot: snapshot, isDemo: true)))
        try store.setDemo(false)
        #expect(JourneyStore(directory: directory).read().journey == nil)
        #expect(!JourneyStore(directory: directory).isDemo)
        try Data("{incomplete".utf8).write(to: directory.appendingPathComponent("journey.json"))
        #expect(JourneyStore(directory: directory).read() == .empty)
    }
}

private struct FixtureTrip: TrainTrip {
    let train = "ICE"
    let vzn = "42"
    let stops: [FixtureStop]
    var trainStops: [any TrainStop] { stops }
    var finalStopInfo: (any TrainFinalStopInfo)? { nil }
}

private struct FixtureStop: TrainStop {
    let id = UUID()
    var trainStation: any TrainStation = FixtureStation(name: "Berlin Hauptbahnhof")
    let scheduledArrival: Date? = Date(timeIntervalSince1970: 1_800_000_000)
    let actualArrival: Date? = Date(timeIntervalSince1970: 1_800_000_060)
    var scheduledDeparture: Date? { nil }
    var actualDeparture: Date? { nil }
    let arrivalDelay = "+1"
    let departureDelay = ""
    let trainTrack: (any TrainTrack)? = FixtureTrack()
    let hasPassed = false
    var isCancelled = false
    var delayReason: String? { nil }
}

private struct FixtureStation: TrainStation {
    let name: String
    let code = "8011160"
    var coordinates: CLLocationCoordinate2D? { nil }
}

private struct FixtureTrack: TrainTrack {
    let scheduled = "8"
    let actual = "9"
}
