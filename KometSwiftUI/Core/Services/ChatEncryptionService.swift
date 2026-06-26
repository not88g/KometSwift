// End-to-end encryption for chats — mirrors services/chat_encryption_service.dart.
// Uses AES-256-CBC with keys stored in Keychain per chat.

import Foundation
import CryptoKit
import Security

actor ChatEncryptionService {
    static let shared = ChatEncryptionService()

    private let keyPrefix = "komet.chatKey."

    // MARK: - Key management

    func generateKey(for chatId: Int) async -> SymmetricKey {
        let key = SymmetricKey(size: .bits256)
        storeKey(key, chatId: chatId)
        return key
    }

    func key(for chatId: Int) async -> SymmetricKey? {
        loadKey(chatId: chatId)
    }

    func isEncryptionEnabled(for chatId: Int) -> Bool {
        UserDefaults.standard.bool(forKey: "encryption_enabled_\(chatId)")
    }

    func setEncryptionEnabled(_ enabled: Bool, for chatId: Int) {
        UserDefaults.standard.set(enabled, forKey: "encryption_enabled_\(chatId)")
    }

    // MARK: - Encrypt / Decrypt

    func encrypt(_ text: String, chatId: Int) async -> String? {
        guard let key = await key(for: chatId),
              let data = text.data(using: .utf8)
        else { return nil }
        do {
            let sealed = try AES.GCM.seal(data, using: key)
            return sealed.combined?.base64EncodedString()
        } catch { return nil }
    }

    func decrypt(_ ciphertext: String, chatId: Int) async -> String? {
        guard let key = await key(for: chatId),
              let data = Data(base64Encoded: ciphertext)
        else { return nil }
        do {
            let sealed = try AES.GCM.SealedBox(combined: data)
            let decrypted = try AES.GCM.open(sealed, using: key)
            return String(data: decrypted, encoding: .utf8)
        } catch { return nil }
    }

    // MARK: - Keychain storage

    private func storeKey(_ key: SymmetricKey, chatId: Int) {
        let keychainKey = keyPrefix + "\(chatId)"
        let data = key.withUnsafeBytes { Data($0) }
        var q: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: "com.komet.encryption",
            kSecAttrAccount as String: keychainKey,
            kSecValueData as String:   data,
        ]
        SecItemDelete(q as CFDictionary)
        SecItemAdd(q as CFDictionary, nil)
    }

    private func loadKey(chatId: Int) -> SymmetricKey? {
        let keychainKey = keyPrefix + "\(chatId)"
        var q: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: "com.komet.encryption",
            kSecAttrAccount as String: keychainKey,
            kSecReturnData as String:  true,
            kSecMatchLimit as String:  kSecMatchLimitOne,
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(q as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data
        else { return nil }
        return SymmetricKey(data: data)
    }
}
