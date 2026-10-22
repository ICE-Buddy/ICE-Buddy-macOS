import SwiftUI
import AppIntents
import WidgetKit
import TrainBuddyKit

struct StartTrainActivityControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "TrainBuddyStartLiveActivity") {
            ControlWidgetButton(action: StartTrainLiveActivityIntent()) {
                Label("Start Train Live Activity", systemImage: "tram.fill")
            }
        }
        .displayName("Start Train Live Activity")
        .description("Start or update your train’s Live Activity in the background using train Wi-Fi.")
    }
}
