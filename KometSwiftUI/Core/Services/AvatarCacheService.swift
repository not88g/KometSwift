// Mirrors services/avatar_cache_service.dart.
// Two-tier: NSCache (hot, in-memory) + disk (warm).

import UIKit

actor AvatarCacheService {
    static let shared = AvatarCacheService()

    private let memCache = NSCache<NSString, UIImage>()
    private var diskRoot: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Avatars", isDirectory: true)
    }

    func initialize() async {
        try? FileManager.default.createDirectory(at: diskRoot, withIntermediateDirectories: true)
        memCache.countLimit = 200
        memCache.totalCostLimit = 50 * 1024 * 1024 // 50 MB
    }

    func avatar(for baseUrl: String) async -> UIImage? {
        let key = cacheKey(baseUrl)

        // Hot
        if let img = memCache.object(forKey: key as NSString) { return img }

        // Warm
        if let img = loadFromDisk(key: key) {
            memCache.setObject(img, forKey: key as NSString)
            return img
        }

        // Cold — fetch from network
        guard let url = URL(string: "\(baseUrl)/200") else { return nil }
        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let img = UIImage(data: data)
        else { return nil }

        memCache.setObject(img, forKey: key as NSString)
        saveToDisk(data: data, key: key)
        return img
    }

    func clearAll() async {
        memCache.removeAllObjects()
        try? FileManager.default.removeItem(at: diskRoot)
        try? FileManager.default.createDirectory(at: diskRoot, withIntermediateDirectories: true)
    }

    private func cacheKey(_ url: String) -> String {
        url.replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: ":", with: "_")
    }

    private func diskURL(key: String) -> URL {
        diskRoot.appendingPathComponent(key + ".jpg")
    }

    private func loadFromDisk(key: String) -> UIImage? {
        guard let data = try? Data(contentsOf: diskURL(key: key)) else { return nil }
        return UIImage(data: data)
    }

    private func saveToDisk(data: Data, key: String) {
        try? data.write(to: diskURL(key: key))
    }
}
