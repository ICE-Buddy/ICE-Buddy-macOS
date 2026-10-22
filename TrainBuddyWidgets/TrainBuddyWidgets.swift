import SwiftUI
import AppIntents
import WidgetKit
import TrainBuddyKit

struct JourneyEntry: TimelineEntry {
    let date: Date
    let record: JourneyRecord
}

struct JourneyTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> JourneyEntry { JourneyEntry(date: .now, record: .empty) }
    func getSnapshot(in context: Context, completion: @escaping (JourneyEntry) -> Void) {
        completion(JourneyEntry(date: .now, record: JourneyStore().read()))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<JourneyEntry>) -> Void) {
        let now = Date()
        let record = JourneyStore().read()
        var entries = [JourneyEntry(date: now, record: record)]
        if let staleAt = record.journey?.fetchedAt.addingTimeInterval(60), staleAt > now {
            entries.append(JourneyEntry(date: staleAt, record: record))
        }
        completion(Timeline(entries: entries, policy: .after(now.addingTimeInterval(15 * 60))))
    }
}

struct TrainBuddyWidgets: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TrainBuddyJourney", provider: JourneyTimelineProvider()) { entry in
            JourneyWidgetView(entry: entry).containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Train journey")
        .description("Next stop, arrival and delays. Refresh directly from the widget using train Wi-Fi.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}

struct JourneyWidgetView: View {
    let entry: JourneyEntry
    @Environment(\.widgetFamily) private var family
    var body: some View {
        Group {
            if family == .accessoryRectangular { AccessoryJourneyView(entry: entry) }
            else { fullJourney }
        }
        .widgetURL(URL(string: "trainbuddy://journey"))
    }

    private var fullJourney: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(entry.record.journey?.serviceName ?? "Train Buddy", systemImage: "tram.fill").font(.headline)
                Spacer(minLength: 2)
                Button(intent: RefreshTrainIntent()) { Image(systemName: "arrow.clockwise") }
                    .buttonStyle(.plain).accessibilityLabel("Refresh live information")
            }
            if let journey = entry.record.journey, let next = journey.nextStop {
                Text(next.station).font(family == .accessoryRectangular ? .subheadline : .headline).lineLimit(2)
                HStack {
                    if let time = next.actualArrival ?? next.scheduledArrival ?? next.actualDeparture ?? next.scheduledDeparture {
                        Text(time, style: .time).monospacedDigit()
                    }
                    let delay = next.scheduledArrival != nil ? next.arrivalDelay : next.departureDelay
                    if !delay.isEmpty { Text("\(delay) min").foregroundStyle(.red) }
                    if family == .systemMedium, let platform = next.platform { Text("Platform \(platform)") }
                }.font(.subheadline)
                if journey.isDemo { Text("Demo · not live").font(.caption).foregroundStyle(.orange) }
                else if entry.record.isStale(at: entry.date) { Text("Outdated · refresh").font(.caption).foregroundStyle(.orange) }
                else if family != .accessoryRectangular { Text(journey.fetchedAt, style: .time).font(.caption).foregroundStyle(.secondary) }
            } else if entry.record.journey != nil {
                Text("No upcoming stops").font(.caption)
            } else {
                Text(entry.record.refreshFailed ? "Check train Wi-Fi" : "Connect to train Wi-Fi, then refresh.")
                    .font(.caption)
            }
        }
    }
}

private struct AccessoryJourneyView: View {
    let entry: JourneyEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(entry.record.journey?.serviceName ?? "Train Buddy").font(.caption.bold())
                if entry.record.journey?.isDemo == true { Text("Demo").font(.caption2) }
                else if entry.record.isStale(at: entry.date) {
                    Image(systemName: "clock.badge.exclamationmark").accessibilityLabel("Outdated")
                }
                Spacer(minLength: 2)
                Button(intent: RefreshTrainIntent()) { Image(systemName: "arrow.clockwise") }
                    .buttonStyle(.plain).accessibilityLabel("Refresh live information")
            }
            if let stop = entry.record.journey?.nextStop {
                Text(stop.station).font(.caption).lineLimit(1)
                HStack {
                    if let time = stop.actualArrival ?? stop.scheduledArrival ?? stop.actualDeparture ?? stop.scheduledDeparture {
                        Text(time, style: .time).monospacedDigit()
                    }
                    let delay = stop.scheduledArrival != nil ? stop.arrivalDelay : stop.departureDelay
                    if !delay.isEmpty { Text("\(delay) min") }
                }.font(.caption2)
            } else { Text("Open Train Buddy").font(.caption) }
        }
    }
}

#Preview(as: .systemSmall) { TrainBuddyWidgets() } timeline: {
    JourneyEntry(date: .now, record: .empty)
}
