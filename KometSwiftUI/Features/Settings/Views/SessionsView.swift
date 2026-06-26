import SwiftUI

struct SessionsView: View {
    @State private var sessions: [[String: Any]] = []
    @State private var isLoading = false

    var body: some View {
        List {
            ForEach(sessions.indices, id: \.self) { i in
                let session = sessions[i]
                VStack(alignment: .leading, spacing: 4) {
                    Text(session["deviceName"] as? String ?? String(localized: "Unknown device"))
                        .font(.kometHeadline)
                    if let platform = session["platform"] as? String {
                        Text(platform).font(.kometCaption).foregroundStyle(.secondary)
                    }
                    if let lastSeen = session["lastSeen"] as? Int {
                        let date = Date(timeIntervalSince1970: Double(lastSeen) / 1000)
                        Text(date, style: .relative).font(.kometCaption2).foregroundStyle(.secondary)
                    }
                }
                .swipeActions {
                    Button(role: .destructive) {
                        if let id = session["id"] as? Int {
                            Task { try? await APIService.shared.terminateSession(sessionId: id) }
                        }
                    } label: {
                        Label(String(localized: "Terminate"), systemImage: "xmark.circle")
                    }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle(String(localized: "Active Sessions"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(String(localized: "Terminate all")) {
                    Task { try? await APIService.shared.terminateAllSessions() }
                }
                .foregroundStyle(.red)
            }
        }
        .overlay { if isLoading { ProgressView() } }
        .task { await load() }
    }

    private func load() async {
        isLoading = true
        sessions = (try? await APIService.shared.fetchSessions()) ?? []
        isLoading = false
    }
}

struct ExportSessionView: View {
    @State private var exportData = ""
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: KometSpacing.xl) {
            if isLoading {
                ProgressView()
            } else if !exportData.isEmpty {
                ScrollView {
                    Text(exportData)
                        .font(.system(.caption, design: .monospaced))
                        .padding()
                        .textSelection(.enabled)
                }
                Button {
                    UIPasteboard.general.string = exportData
                } label: {
                    Label(String(localized: "Copy"), systemImage: "doc.on.doc")
                }
                .buttonStyle(.borderedProminent)
            } else {
                KometButton(String(localized: "Export Session Data"), isLoading: isLoading) {
                    Task { await export() }
                }
                .padding(.horizontal, KometSpacing.xl)
            }
        }
        .navigationTitle(String(localized: "Export Session"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func export() async {
        isLoading = true
        exportData = (try? await APIService.shared.exportSession()) ?? ""
        isLoading = false
    }
}
