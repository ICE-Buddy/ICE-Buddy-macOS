import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit
import TrainBuddyKit

struct TrainBuddyLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TrainActivityAttributes.self) { context in
            LiveJourneyView(state: context.state, isStale: context.isStale)
                .padding()
                .activityBackgroundTint(.black)
                .activitySystemActionForegroundColor(.white)
                .foregroundStyle(.white)
                .widgetURL(URL(string: "trainbuddy://journey"))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(context.state.serviceName, systemImage: "tram.fill").font(.headline)
                }
                DynamicIslandExpandedRegion(.trailing) { RefreshActivityButton() }
                DynamicIslandExpandedRegion(.bottom) {
                    LiveJourneyView(state: context.state, isStale: context.isStale, showsHeader: false)
                }
            } compactLeading: {
                Image(systemName: "tram.fill").accessibilityLabel(context.state.serviceName)
            } compactTrailing: {
                if context.state.isDemo { Text("Demo").font(.caption) }
                else if context.isStale || context.state.refreshFailed { Image(systemName: "exclamationmark.arrow.circlepath") }
                else if !context.state.delay.isEmpty { Text("\(context.state.delay)′").foregroundStyle(.red) }
                else if let time = context.state.actualArrival ?? context.state.scheduledArrival { Text(time, style: .time) }
                else { Image(systemName: "wifi") }
            } minimal: {
                Image(systemName: context.isStale || context.state.refreshFailed ? "wifi.exclamationmark" : "tram.fill")
            }
            .widgetURL(URL(string: "trainbuddy://journey"))
        }
    }
}

private struct LiveJourneyView: View {
    let state: LiveJourneyState
    let isStale: Bool
    var showsHeader = true
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if showsHeader {
                HStack {
                    Label(state.serviceName, systemImage: "tram.fill").font(.headline)
                    Spacer()
                    RefreshActivityButton()
                }
            }
            if !state.nextStation.isEmpty {
                Text(state.nextStation).font(.headline).lineLimit(2)
                HStack {
                    if let time = state.actualArrival ?? state.scheduledArrival { Text(time, style: .time).monospacedDigit() }
                    if !state.delay.isEmpty { Text("\(state.delay) min").foregroundStyle(.red) }
                    if let platform = state.platform { Text("Platform \(platform)") }
                    Spacer(minLength: 4)
                    if let speed = state.speedKilometersPerHour { Text("\(speed) km/h") }
                }.font(.subheadline)
            } else {
                Text(state.isRefreshing ? "Fetching train information…" : state.fetchedAt != nil ? "No upcoming stops" : "Connect to train Wi-Fi, then refresh.")
                    .font(.subheadline)
            }
            if state.isDemo { Text("Demo · not live").foregroundStyle(.orange).font(.caption) }
            else if state.refreshFailed { Text("Couldn’t refresh · check train Wi-Fi").foregroundStyle(.orange).font(.caption) }
            else if isStale { Text("Outdated · refresh for live information").foregroundStyle(.orange).font(.caption) }
            if let date = state.fetchedAt { Text("Updated \(date, style: .relative) ago").font(.caption2).foregroundStyle(.secondary) }
        }
    }
}

private struct RefreshActivityButton: View {
    var body: some View {
        Button(intent: RefreshTrainIntent()) { Label("Refresh", systemImage: "arrow.clockwise") }
            .labelStyle(.iconOnly).buttonStyle(.bordered)
            .accessibilityLabel("Refresh live information")
    }
}
