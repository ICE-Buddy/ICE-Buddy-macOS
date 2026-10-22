#if os(iOS)
import Foundation
import Observation
import SwiftUI
import UIKit
import WidgetKit
@preconcurrency import TrainConnect
@preconcurrency import DBConnect
@preconcurrency import SNCFConnect
@preconcurrency import OnboardConnect

@Observable @MainActor
public final class JourneyService {
    public static let shared = JourneyService()
    public private(set) var record: JourneyRecord
    public private(set) var isRefreshing = false
    public private(set) var isDemo: Bool
    public private(set) var storageFailed = false
    public private(set) var activityActive = false
    private let store = JourneyStore()
    private var pending: Task<JourneyRecord, Never>?

    private init() {
        record = store.read()
        isDemo = store.isDemo
        activityActive = TrainLiveActivity.isActive
    }

    func synchronizeActivityState() { activityActive = TrainLiveActivity.isActive }

    @discardableResult
    public func refresh() async -> JourneyRecord {
        if let pending { return await pending.value }
        let task = Task { await fetchAndPublish() }
        pending = task
        let result = await task.value
        pending = nil
        return result
    }

    public func setDemo(_ enabled: Bool) async {
        if let pending { _ = await pending.value }
        guard enabled != isDemo else { return }
        do {
            try store.setDemo(enabled)
            isDemo = enabled
            record = .empty
            storageFailed = false
            #if canImport(ActivityKit)
            await TrainLiveActivity.end()
            #endif
            await refresh()
        } catch { storageFailed = true }
    }

    private func fetchAndPublish() async -> JourneyRecord {
        isRefreshing = true
        defer { isRefreshing = false }
        // Each completed manual refresh starts a new provider race, bypassing the
        // desktop controller's five-second cache. Only in-flight calls are shared.
        let controller = CombinedDataController(controllers: ICEDataController.shared, TGVDataController.shared,
            RailnetDataController.shared, CDDataController.shared, DBRegioDataController.shared)
        let demo = isDemo
        let journey: TrainJourney? = await withCheckedContinuation { continuation in
            controller.loadSnapshot(demoMode: demo) { snapshot, _ in
                // CombinedDataController guarantees delivery on the main queue.
                MainActor.assumeIsolated {
                    let journey = snapshot.map { snapshot in
                        let artwork = (snapshot.trainType?.trainIcon ?? ICETrainType(tzn: "").trainIcon).flatMap { image in
                            ImageRenderer(content: image.resizable().scaledToFit().frame(width: 600, height: 140)).uiImage?.pngData()
                        }
                        return TrainJourney(snapshot: snapshot, isDemo: demo, artworkPNG: artwork)
                    }
                    continuation.resume(returning: journey)
                }
            }
        }
        record = journey.map { record.receiving($0) } ?? record.failing(at: .now)
        do {
            try store.save(record)
            storageFailed = false
        } catch { storageFailed = true }
        WidgetCenter.shared.reloadAllTimelines()
        #if canImport(ActivityKit)
        await TrainLiveActivity.update(record)
        #endif
        return record
    }

    public func diagnosticReport() -> String {
        APIDiagnostics.shared.makeReport(
            applicationVersion: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "",
            build: Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "", isDemo: isDemo)
    }
}
#endif
