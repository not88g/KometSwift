import UIKit

// General-purpose image disk cache used by non-avatar images (chat backgrounds, etc.)
actor ImageDiskCache {
    static let shared = ImageDiskCache()

    private var root: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Images", isDirectory: true)
    }

    func initialize() async {
        try? FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }

    func image(for url: URL) async -> UIImage? {
        let key = cacheKey(url)
        let file = root.appendingPathComponent(key)
        if let data = try? Data(contentsOf: file) { return UIImage(data: data) }

        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let img = UIImage(data: data)
        else { return nil }

        try? data.write(to: file)
        return img
    }

    func clear() async {
        try? FileManager.default.removeItem(at: root)
        try? FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }

    private func cacheKey(_ url: URL) -> String {
        url.absoluteString
            .replacingOccurrences(of: "://", with: "_")
            .replacingOccurrences(of: "/", with: "_")
    }
}
