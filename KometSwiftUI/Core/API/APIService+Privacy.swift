// Privacy & security API — mirrors api_service_privacy.dart.

import Foundation

extension APIService {

    func fetchPrivacySettings() async throws -> [String: Any] {
        return try await request(opcode: 100, payload: [:])
    }

    func updatePrivacySetting(key: String, value: String) async throws {
        try await sendMessage(opcode: 101, payload: ["key": key, "value": value])
    }

    func fetchProfile(userId: Int? = nil) async throws -> Profile? {
        var payload: [String: Any] = [:]
        if let id = userId { payload["userId"] = id }
        let response = try await request(opcode: 102, payload: payload)
        guard let raw = response["profile"] as? [String: Any] else { return nil }
        return Profile(from: raw)
    }

    func updateProfile(firstName: String, lastName: String, description: String?) async throws {
        var payload: [String: Any] = ["firstName": firstName, "lastName": lastName]
        if let d = description { payload["description"] = d }
        try await sendMessage(opcode: 103, payload: payload)
    }

    func fetchSessions() async throws -> [[String: Any]] {
        let response = try await request(opcode: 96, payload: [:])
        return response["sessions"] as? [[String: Any]] ?? []
    }

    func exportSession() async throws -> String {
        let response = try await request(opcode: 104, payload: [:])
        return response["exportData"] as? String ?? ""
    }
}
