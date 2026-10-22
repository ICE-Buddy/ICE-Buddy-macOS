import AppKit
import TrainConnect
import UniformTypeIdentifiers

/// Explicit user-initiated preview/export. Preparing a draft never sends an email.
final class APIDiagnosticsController: NSObject, NSSharingServiceDelegate {
    static let recipient = "trainbuddy@riedel.wtf"
    private var sharingService: NSSharingService?
    private var draftReport: String?

    func showReport() {
        let report = APIDiagnostics.shared.makeReport(
            applicationVersion: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown",
            build: Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "unknown",
            isDemo: demoMode)
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("API diagnostics", comment: "")
        alert.informativeText = String(format: NSLocalizedString("Review the report before sharing it with %@. It contains recent technical API results and app/system versions, without locations, Wi-Fi identifiers or response contents. Failed probes for other train operators are normal.", comment: ""), Self.recipient)
        alert.addButton(withTitle: NSLocalizedString("Prepare email", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("Save report…", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))
        alert.accessoryView = reportPreview(report)
        NSApp.activate(ignoringOtherApps: true)
        switch alert.runModal() {
        case .alertFirstButtonReturn: prepareEmail(report)
        case .alertSecondButtonReturn: saveReport(report)
        default: break
        }
    }

    private func reportPreview(_ report: String) -> NSScrollView {
        let scroll = NSScrollView(frame: NSRect(x: 0, y: 0, width: 520, height: 260))
        scroll.hasVerticalScroller = true
        scroll.borderType = .bezelBorder
        let text = NSTextView(frame: scroll.contentView.bounds)
        text.isEditable = false
        text.isSelectable = true
        text.isRichText = false
        text.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        text.string = report
        text.textContainerInset = NSSize(width: 8, height: 8)
        text.minSize = NSSize(width: 0, height: scroll.contentSize.height)
        text.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        text.isVerticallyResizable = true
        text.isHorizontallyResizable = false
        text.autoresizingMask = [.width]
        text.textContainer?.containerSize = NSSize(width: scroll.contentSize.width, height: CGFloat.greatestFiniteMagnitude)
        text.textContainer?.widthTracksTextView = true
        text.setAccessibilityLabel(NSLocalizedString("API diagnostics", comment: ""))
        scroll.documentView = text
        return scroll
    }

    private func prepareEmail(_ report: String) {
        let intro = NSLocalizedString("Please describe what happened and which train operator you were travelling with:", comment: "")
        let body = intro + "\n\n\n--- Train Buddy API diagnostics ---\n" + report
        guard let service = NSSharingService(named: .composeEmail), service.canPerform(withItems: [body]) else {
            offerExport(report)
            return
        }
        service.recipients = [Self.recipient]
        service.subject = "Train Buddy API diagnostics"
        service.delegate = self
        draftReport = report
        sharingService = service
        service.perform(withItems: [body])
    }

    private func saveReport(_ report: String) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "Train-Buddy-diagnostics.json"
        panel.allowedContentTypes = [.json]
        panel.canCreateDirectories = true
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do { try report.write(to: url, atomically: true, encoding: .utf8) }
        catch {
            let alert = NSAlert()
            alert.messageText = NSLocalizedString("The diagnostic report could not be saved.", comment: "")
            alert.informativeText = NSLocalizedString("Choose another location and try again.", comment: "")
            alert.runModal()
        }
    }

    private func offerExport(_ report: String) {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("Email could not be prepared", comment: "")
        alert.informativeText = String(format: NSLocalizedString("Save the report and attach it to an email to %@, for example in webmail. Nothing has been sent.", comment: ""), Self.recipient)
        alert.addButton(withTitle: NSLocalizedString("Save report…", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))
        if alert.runModal() == .alertFirstButtonReturn { saveReport(report) }
    }

    func sharingService(_ sharingService: NSSharingService, didFailToShareItems items: [Any], error: Error) {
        guard self.sharingService === sharingService else { return }
        let report = draftReport
        self.sharingService = nil
        draftReport = nil
        let nsError = error as NSError
        guard !(nsError.domain == NSCocoaErrorDomain && nsError.code == NSUserCancelledError) else { return }
        if let report = report { offerExport(report) }
    }

    func sharingService(_ sharingService: NSSharingService, didShareItems items: [Any]) {
        guard self.sharingService === sharingService else { return }
        self.sharingService = nil
        draftReport = nil
    }
}
