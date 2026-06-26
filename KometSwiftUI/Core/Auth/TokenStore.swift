// Stores auth token in the iOS Keychain — equivalent of flutter_secure_storage.
// Key names intentionally match the Flutter SharedPreferences keys for migration awareness.

import Foundation
import Security

actor TokenStore {
    static let shared = TokenStore()

    private let service = "com.komet.app"
    private let tokenKey = "authToken"
    private let userIdKey = "authUserId"

    func saveToken(_ token: String, userId: Int) async {
        set(value: token, forKey: tokenKey)
        set(value: String(userId), forKey: userIdKey)
    }

    func loadToken() async -> String? {
        get(forKey: tokenKey)
    }

    func loadUserId() async -> Int? {
        get(forKey: userIdKey).flatMap { Int($0) }
    }

    func hasToken() async -> Bool {
        get(forKey: tokenKey) != nil
    }

    func clearToken() async {
        delete(forKey: tokenKey)
        delete(forKey: userIdKey)
    }

    // MARK: - Keychain helpers

    private func set(value: String, forKey key: String) {
        let data = Data(value.utf8)
        var query = baseQuery(key: key)
        query[kSecValueData as String] = data
        SecItemDelete(baseQuery(key: key) as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    private func get(forKey key: String) -> String? {
        var query = baseQuery(key: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func delete(forKey key: String) {
        SecItemDelete(baseQuery(key: key) as CFDictionary)
    }

    private func baseQuery(key: String) -> [String: Any] {
        [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
    }
}
