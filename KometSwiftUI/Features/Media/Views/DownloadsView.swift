import SwiftUI

struct DownloadsView: View {
    @State private var files: [URL] = []

    var body: some View {
        List {
            ForEach(files, id: \.self) { url in
                HStack {
                    Image(systemName: fileIcon(url))
                        .font(.system(size: 28))
                        .foregroundStyle(.kometAccent)
                    VStack(alignment: .leading) {
                        Text(url.lastPathComponent).font(.kometHeadline).lineLimit(1)
                        if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
                           let size = attrs[.size] as? Int {
                            Text(ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file))
                                .font(.kometCaption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Button { share(url) } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
                .swipeActions {
                    Button(role: .destructive) {
                        try? FileManager.default.removeItem(at: url)
                        files.removeAll { $0 == url }
                    } label: {
                        Label(String(localized: "Delete"), systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle(String(localized: "Downloads"))
        .overlay {
            if files.isEmpty {
                ContentUnavailableView(
                    String(localized: "No downloads"),
                    systemImage: "arrow.down.circle",
                    description: Text(String(localized: "Files you download will appear here"))
                )
            }
        }
        .onAppear { loadFiles() }
    }

    private func loadFiles() {
        guard let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let downloadsDir = docs.appendingPathComponent("Downloads")
        files = (try? FileManager.default.contentsOfDirectory(at: downloadsDir, includingPropertiesForKeys: nil)) ?? []
    }

    private func fileIcon(_ url: URL) -> String {
        switch url.pathExtension.lowercased() {
        case "jpg","jpeg","png","gif","webp": return "photo"
        case "mp4","mov","avi":              return "video"
        case "mp3","ogg","m4a","wav":        return "music.note"
        case "pdf":                          return "doc.richtext"
        default:                             return "doc"
        }
    }

    private func share(_ url: URL) {
        let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            root.present(vc, animated: true)
        }
    }
}
