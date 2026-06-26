import SwiftUI

struct StorageView: View {
    @State private var cacheSize: Int64 = 0
    @State private var avatarSize: Int64 = 0
    @State private var messageSize: Int64 = 0
    @State private var isClearing = false

    var body: some View {
        Form {
            Section(String(localized: "Usage")) {
                storageRow(label: String(localized: "Avatars"),  size: avatarSize)
                storageRow(label: String(localized: "Messages"), size: messageSize)
                storageRow(label: String(localized: "General cache"), size: cacheSize)
            }

            Section {
                Button(String(localized: "Clear all cache"), role: .destructive) {
                    Task { await clearAll() }
                }
                .disabled(isClearing)
            }
        }
        .navigationTitle(String(localized: "Storage"))
        .navigationBarTitleDisplayMode(.inline)
        .task { calculateSizes() }
    }

    private func storageRow(label: String, size: Int64) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))
                .foregroundStyle(.secondary)
        }
    }

    private func calculateSizes() {
        cacheSize   = directorySize(FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("KometCache"))
        avatarSize  = directorySize(FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("Avatars"))
        messageSize = 0
    }

    private func directorySize(_ url: URL) -> Int64 {
        guard let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) else { return 0 }
        return enumerator.compactMap { $0 as? URL }
            .compactMap { try? $0.resourceValues(forKeys: [.fileSizeKey]).fileSize }
            .reduce(0) { Int64($0) + Int64($1) }
    }

    private func clearAll() async {
        isClearing = true
        await CacheService.shared.clearAll()
        await AvatarCacheService.shared.clearAll()
        await ChatCacheService.shared.clearAll()
        await ProfileCacheService.shared.clearAll()
        calculateSizes()
        isClearing = false
    }
}

struct CacheManagementView: View {
    var body: some View {
        Form {
            Section {
                Button(String(localized: "Clear message cache")) {
                    Task { await ChatCacheService.shared.clearAll() }
                }
                Button(String(localized: "Clear avatar cache")) {
                    Task { await AvatarCacheService.shared.clearAll() }
                }
                Button(String(localized: "Clear profile cache")) {
                    Task { await ProfileCacheService.shared.clearAll() }
                }
            }
            Section {
                Button(String(localized: "Clear all cache"), role: .destructive) {
                    Task {
                        await CacheService.shared.clearAll()
                        await AvatarCacheService.shared.clearAll()
                        await ChatCacheService.shared.clearAll()
                    }
                }
            }
        }
        .navigationTitle(String(localized: "Cache Management"))
        .navigationBarTitleDisplayMode(.inline)
    }
}
