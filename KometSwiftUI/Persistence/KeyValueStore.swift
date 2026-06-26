import Foundation

// Thread-safe UserDefaults wrapper.
final class KeyValueStore {
    static let shared = KeyValueStore()
    private let defaults = UserDefaults.standard

    func set(_ value: Any?, forKey key: String) { defaults.set(value, forKey: key) }
    func string(forKey key: String) -> String?   { defaults.string(forKey: key) }
    func int(forKey key: String) -> Int          { defaults.integer(forKey: key) }
    func bool(forKey key: String) -> Bool        { defaults.bool(forKey: key) }
    func data(forKey key: String) -> Data?       { defaults.data(forKey: key) }
    func remove(forKey key: String)              { defaults.removeObject(forKey: key) }
}
