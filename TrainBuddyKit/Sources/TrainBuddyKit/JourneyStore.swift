import Foundation

/// Atomic files let the app and WidgetKit read a complete snapshot across processes.
public struct JourneyStore: Sendable {
    public static let appGroup = "group.wtf.riedel.TrainBuddy"
    private let directory: URL?

    public init() {
        directory = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Self.appGroup)
    }

    public init(directory: URL) { self.directory = directory }

    public func read() -> JourneyRecord {
        guard let directory,
              let data = try? Data(contentsOf: directory.appendingPathComponent("journey.json")),
              let record = try? JSONDecoder().decode(JourneyRecord.self, from: data) else { return .empty }
        return record
    }

    public func save(_ record: JourneyRecord) throws {
        try write(JSONEncoder().encode(record), name: "journey.json")
    }

    public var isDemo: Bool {
        guard let directory,
              let data = try? Data(contentsOf: directory.appendingPathComponent("demo.json")) else { return false }
        return (try? JSONDecoder().decode(Bool.self, from: data)) ?? false
    }

    public func setDemo(_ enabled: Bool) throws {
        try write(JSONEncoder().encode(enabled), name: "demo.json")
        try save(.empty)
    }

    private func write(_ data: Data, name: String) throws {
        guard let directory else { throw CocoaError(.fileNoSuchFile) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent(name)
        try data.write(to: url, options: .atomic)
        #if os(iOS)
        try FileManager.default.setAttributes([.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication], ofItemAtPath: url.path)
        #endif
    }
}
