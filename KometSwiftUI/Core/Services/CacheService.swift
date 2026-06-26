import Foundation

// Generic disk-backed JSON cache — mirrors services/cache_service.dart.
actor CacheService {
    static let shared = CacheService()

    func initialize() async {
        try? FileManager.default.createDirectory(at: cacheRoot, withIntermediateDirectories: true)
    }

    func store<T: Encodable>(_ value: T, forKey key: String) async {
        guard let data = try? JSONEncoder().encode(value) else { return }
        try? data.write(to: fileURL(key))
    }

    func load<T: Decodable>(_ type: T.Type, forKey key: String) async -> T? {
        guard let data = try? Data(contentsOf: fileURL(key)) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    func remove(forKey key: String) async {
        try? FileManager.default.removeItem(at: fileURL(key))
    }

    func clearAll() async {
        try? FileManager.default.removeItem(at: cacheRoot)
        try? FileManager.default.createDirectory(at: cacheRoot, withIntermediateDirectories: true)
    }

    private var cacheRoot: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("KometCache", isDirectory: true)
    }

    private func fileURL(_ key: String) -> URL {
        cacheRoot.appendingPathComponent(key.replacingOccurrences(of: "/", with: "_") + ".json")
    }
}
