import AppIntents
import TrainBuddyKit

struct TrainShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: StartTrainLiveActivityIntent(), phrases: [
            "Start my train journey in \(.applicationName)"
        ], shortTitle: "Start Live Activity", systemImageName: "tram.fill")
        AppShortcut(intent: RefreshTrainIntent(), phrases: [
            "Refresh my train in \(.applicationName)"
        ], shortTitle: "Refresh train", systemImageName: "arrow.clockwise")
    }
}
