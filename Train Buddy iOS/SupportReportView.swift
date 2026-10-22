import SwiftUI

struct SupportReportView: View {
    let report: String
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Review these diagnostics before sharing. The report excludes station names, coordinates, Wi-Fi identifiers, headers and response contents.")
                    Text(report).font(.system(.caption, design: .monospaced)).textSelection(.enabled)
                    Button("Prepare email to trainbuddy@riedel.wtf") { prepareEmail() }
                        .buttonStyle(.borderedProminent)
                    ShareLink(item: report, subject: Text("Train Buddy API diagnostics"), message: Text("API problem report")) {
                        Label("Share diagnostics…", systemImage: "square.and.arrow.up")
                    }
                    Text("Add a short description of the problem. Nothing is sent automatically. If you don’t use Apple Mail, use Share diagnostics.")
                        .font(.footnote).foregroundStyle(.secondary)
                }.padding()
            }
            .navigationTitle("API diagnostics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { Button("Done") { dismiss() } }
        }
    }

    private func prepareEmail() {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = "trainbuddy@riedel.wtf"
        components.queryItems = [URLQueryItem(name: "subject", value: "Train Buddy API diagnostics"),
            URLQueryItem(name: "body", value: "Describe the problem here:\n\n\n" + report)]
        if let url = components.url { openURL(url) }
    }
}
