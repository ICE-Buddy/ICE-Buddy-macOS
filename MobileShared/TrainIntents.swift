#if os(iOS)
import AppIntents
import TrainBuddyKit

public struct StartTrainLiveActivityIntent: LiveActivityIntent {
    public static let title: LocalizedStringResource = "Start Train Live Activity"
    public static let description = IntentDescription("Show your train on the Lock Screen and Dynamic Island. Connect to train Wi-Fi first.")
    public static var openAppWhenRun: Bool { false }
    public init() {}

    public func perform() async throws -> some IntentResult {
        try await TrainLiveActivity.start()
        return .result()
    }
}

/// LiveActivityIntent routes execution to the app process, including a widget tap.
/// Each action fetches from the network, then updates shared storage and activities.
public struct RefreshTrainIntent: LiveActivityIntent {
    public static let title: LocalizedStringResource = "Refresh Train Information"
    public static let description = IntentDescription("Fetch current information from the train’s Wi-Fi portal.")
    public static var openAppWhenRun: Bool { false }
    public init() {}

    public func perform() async throws -> some IntentResult {
        await JourneyService.shared.refresh()
        return .result()
    }
}
#endif
