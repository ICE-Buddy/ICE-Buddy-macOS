import SwiftUI
import UIKit
import TrainBuddyKit

struct JourneyHeader: View {
    let journey: TrainJourney
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let data = journey.artworkPNG, let image = UIImage(data: data) {
                Image(uiImage: image).resizable().scaledToFit().frame(maxHeight: 90).accessibilityHidden(true)
            }
            Text(journey.serviceName).font(.title.bold())
            Label(journey.destination, systemImage: "arrow.right").font(.headline)
            if let model = journey.vehicleModel { Text(model).foregroundStyle(.secondary) }
            if let speed = journey.speedKilometersPerHour {
                Label("\(speed) km/h", systemImage: "speedometer").monospacedDigit()
            }
        }
        .padding(.vertical, 8)
    }
}

struct JourneyStopRow: View {
    let stop: JourneyStop
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(stop.station).font(.headline).fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 8)
                if let platform = stop.platform {
                    VStack(alignment: .trailing) {
                        Text("Platform \(platform)").font(.subheadline)
                        if let planned = stop.scheduledPlatform, planned != platform {
                            Text(planned).strikethrough().foregroundStyle(.secondary).font(.caption)
                        }
                    }
                }
            }
            if stop.isCancelled { Label("Cancelled", systemImage: "xmark.circle.fill").foregroundStyle(.red) }
            if stop.scheduledArrival != nil || stop.actualArrival != nil {
                StopTimeRow(label: "Arrival", scheduled: stop.scheduledArrival, actual: stop.actualArrival, delay: stop.arrivalDelay)
            }
            if stop.scheduledDeparture != nil || stop.actualDeparture != nil {
                StopTimeRow(label: "Departure", scheduled: stop.scheduledDeparture, actual: stop.actualDeparture, delay: stop.departureDelay)
            }
            if let reason = stop.delayReason, !reason.isEmpty { Text(reason).font(.caption).foregroundStyle(.secondary) }
            if stop.hasPassed { Text("Passed").font(.caption).foregroundStyle(.secondary) }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

private struct StopTimeRow: View {
    let label: LocalizedStringKey
    let scheduled: Date?
    let actual: Date?
    let delay: String
    var body: some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            if let scheduled { Text(scheduled, style: .time).foregroundStyle(.secondary) }
            if let actual, actual != scheduled { Text(actual, style: .time) }
            if !delay.isEmpty { Text("\(delay) min").foregroundStyle(delay.hasPrefix("+") ? Color.red : Color.primary) }
        }
        .font(.subheadline).monospacedDigit()
    }
}

struct FreshnessLabel: View {
    let record: JourneyRecord
    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            HStack {
                if let date = record.journey?.fetchedAt {
                    Text("Updated \(date, style: .relative) ago")
                    if record.isStale(at: context.date) { Text("Outdated").foregroundStyle(.orange) }
                } else { Text("No live data yet") }
            }
            .font(.caption).foregroundStyle(.secondary)
        }
    }
}
