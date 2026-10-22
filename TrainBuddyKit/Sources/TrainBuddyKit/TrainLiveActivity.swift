#if os(iOS)
import ActivityKit
import Foundation

public struct TrainActivityAttributes: ActivityAttributes, Sendable {
    public typealias ContentState = LiveJourneyState
    public let startedAt: Date
    public init(startedAt: Date = .now) { self.startedAt = startedAt }
}

@MainActor
public enum TrainLiveActivity {
    public static var isActive: Bool {
        Activity<TrainActivityAttributes>.activities.contains { $0.activityState == .active || $0.activityState == .stale }
    }

    /// Also called by LiveActivityIntent, which permits a start from Control Center.
    public static func start() async throws {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { throw LiveActivityError.disabled }
        let service = JourneyService.shared
        if !isActive {
            let state = LiveJourneyState(record: service.record, isRefreshing: true, isDemo: service.isDemo)
            _ = try Activity.request(attributes: TrainActivityAttributes(), content: content(state), pushType: nil)
        }
        service.synchronizeActivityState()
        await service.refresh()
    }

    public static func update(_ record: JourneyRecord) async {
        JourneyService.shared.synchronizeActivityState()
        for activity in Activity<TrainActivityAttributes>.activities {
            await activity.update(content(LiveJourneyState(record: record, isDemo: JourneyService.shared.isDemo)))
        }
    }

    public static func end() async {
        for activity in Activity<TrainActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        JourneyService.shared.synchronizeActivityState()
    }

    private static func content(_ state: LiveJourneyState) -> ActivityContent<LiveJourneyState> {
        ActivityContent(state: state, staleDate: state.fetchedAt?.addingTimeInterval(60) ?? Date().addingTimeInterval(30))
    }
}

public enum LiveActivityError: LocalizedError {
    case disabled
    public var errorDescription: String? {
        String(localized: "Enable Live Activities for Train Buddy in Settings.", bundle: .main)
    }
}
#endif
