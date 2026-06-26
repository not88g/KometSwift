// Contacts API — mirrors api_service_contacts.dart.

import Foundation

extension APIService {

    func fetchContacts() async throws -> [Contact] {
        let response = try await request(opcode: 70, payload: [:])
        return (response["contacts"] as? [[String: Any]] ?? []).map { Contact(from: $0) }
    }

    func searchContacts(query: String) async throws -> [Contact] {
        let response = try await request(opcode: 71, payload: ["query": query])
        return (response["contacts"] as? [[String: Any]] ?? []).map { Contact(from: $0) }
    }

    func searchById(userId: Int) async throws -> Contact? {
        let response = try await request(opcode: 72, payload: ["userId": userId])
        guard let raw = response["contact"] as? [String: Any] else { return nil }
        return Contact(from: raw)
    }

    func fetchContact(userId: Int) async throws -> Contact? {
        let response = try await request(opcode: 73, payload: ["userId": userId])
        guard let raw = response["contact"] as? [String: Any] else { return nil }
        return Contact(from: raw)
    }

    func blockContact(userId: Int) async throws {
        try await sendMessage(opcode: 74, payload: ["userId": userId])
    }

    func unblockContact(userId: Int) async throws {
        try await sendMessage(opcode: 75, payload: ["userId": userId])
    }

    func fetchBlockedContacts() async throws -> [Contact] {
        let response = try await request(opcode: 76, payload: [:])
        return (response["contacts"] as? [[String: Any]] ?? []).map { Contact(from: $0) }
    }

    func editContactLocalName(userId: Int, firstName: String, lastName: String) async throws {
        try await sendMessage(opcode: 77, payload: [
            "userId": userId, "firstName": firstName, "lastName": lastName
        ])
    }

    func joinGroupByLink(link: String) async throws -> Chat {
        let response = try await request(opcode: 80, payload: ["link": link])
        guard let raw = response["chat"] as? [String: Any] else { throw APIError.missingField("chat") }
        return Chat(from: raw)
    }

    func fetchGroupParticipants(chatId: Int) async throws -> [Contact] {
        let response = try await request(opcode: 81, payload: ["chatId": chatId])
        return (response["participants"] as? [[String: Any]] ?? []).map { Contact(from: $0) }
    }

    func kickParticipant(chatId: Int, userId: Int) async throws {
        try await sendMessage(opcode: 82, payload: ["chatId": chatId, "userId": userId])
    }

    func promoteParticipant(chatId: Int, userId: Int) async throws {
        try await sendMessage(opcode: 83, payload: ["chatId": chatId, "userId": userId])
    }

    func leaveGroup(chatId: Int) async throws {
        try await sendMessage(opcode: 84, payload: ["chatId": chatId])
    }

    func updateGroupSettings(chatId: Int, title: String?, description: String?) async throws {
        var payload: [String: Any] = ["chatId": chatId]
        if let t = title { payload["title"] = t }
        if let d = description { payload["description"] = d }
        try await sendMessage(opcode: 85, payload: payload)
    }
}
