import SwiftUI
import TrainBuddyKit

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var service = JourneyService.shared
    @State private var showingSupport = false
    @State private var activityError: String?

    var body: some View {
        NavigationStack {
            List {
                if service.isDemo {
                    Label("Demo data · not live", systemImage: "play.rectangle")
                        .foregroundStyle(.orange)
                }
                if let journey = service.record.journey {
                    Section { JourneyHeader(journey: journey) }
                    Section("Next stop") {
                        if let stop = journey.nextStop { JourneyStopRow(stop: stop) }
                        else { Text("No upcoming stops") }
                    }
                } else {
                    ContentUnavailableView("Connect to train Wi-Fi", systemImage: "wifi", description:
                        Text("Join the train’s Wi-Fi, open its portal if required, then refresh. Allow local network access when asked."))
                }
                Section {
                    Button { Task { await refresh() } } label: {
                        Label(service.isRefreshing ? "Refreshing…" : "Refresh live information", systemImage: "arrow.clockwise")
                    }
                    .disabled(service.isRefreshing)
                    .accessibilityIdentifier("refreshJourney")
                    FreshnessLabel(record: service.record)
                    if service.record.refreshFailed {
                        Label("Couldn’t refresh. Check train Wi-Fi and local network access.", systemImage: "wifi.exclamationmark")
                            .foregroundStyle(.orange)
                    }
                    if service.storageFailed {
                        Text("Widgets couldn’t access shared storage. Please reopen Train Buddy.")
                            .foregroundStyle(.orange)
                    }
                }
                Section("Live Activity") {
                    Button { Task { await startActivity() } } label: {
                        Label(service.activityActive ? "Update Live Activity" : "Start Live Activity", systemImage: "waveform.path")
                    }
                    .accessibilityIdentifier("startLiveActivity")
                    if service.activityActive {
                        Button("End Live Activity", role: .destructive) {
                            Task { await TrainLiveActivity.end() }
                        }
                    }
                    Text("Refresh on your Lock Screen or Dynamic Island. Add “Start Train Live Activity” in Control Center to start it in the background.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                if let journey = service.record.journey {
                    Section("Journey") {
                        ForEach(journey.stops) { JourneyStopRow(stop: $0) }
                    }
                }
                Section {
                    Toggle("Demo mode", isOn: Binding(get: { service.isDemo }, set: { enabled in
                        Task { await service.setDemo(enabled) }
                    }))
                    Button("Report API problem…") { showingSupport = true }
                }
            }
            .navigationTitle("Train Buddy")
            .refreshable { await refresh() }
            .toolbar {
                Button { Task { await refresh() } } label: { Label("Refresh", systemImage: "arrow.clockwise") }
                    .disabled(service.isRefreshing)
            }
            .sheet(isPresented: $showingSupport) { SupportReportView(report: service.diagnosticReport()) }
            .alert("Live Activity", isPresented: Binding(get: { activityError != nil }, set: { if !$0 { activityError = nil } })) {
                Button("OK", role: .cancel) { activityError = nil }
            } message: { Text(activityError ?? "") }
            .task(id: scenePhase) {
                guard scenePhase == .active else { return }
                if ProcessInfo.processInfo.arguments.contains("--demo"), !service.isDemo {
                    await service.setDemo(true)
                }

                while !Task.isCancelled {
                    await refresh()
                    do { try await Task.sleep(for: .seconds(30)) } catch { break }
                }
            }
        }
    }

    private func refresh() async { await service.refresh() }
    private func startActivity() async {
        do { try await TrainLiveActivity.start() }
        catch { activityError = error.localizedDescription }
    }
}

#Preview {
    ContentView()
}
