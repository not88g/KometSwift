// Chat & message API — mirrors api_service_chats.dart.

import Foundation

extension APIService {

    // MARK: - Chats

    func fetchChats(limit: Int = 50, offset: Int = 0) async throws -> [Chat] {
        let response = try await request(opcode: 50, payload: ["limit": limit, "offset": offset])
        let rawChats = response["chats"] as? [[String: Any]] ?? []
        return rawChats.map { Chat(from: $0) }
    }

    func fetchFolders() async throws -> [ChatFolder] {
        let response = try await request(opcode: 55, payload: [:])
        let raw = response["folders"] as? [[String: Any]] ?? []
        return raw.map { ChatFolder(from: $0) }
    }

    func createGroupChat(title: String, participantIds: [Int]) async throws -> Chat {
        let payload: [String: Any] = ["title": title, "participants": participantIds]
        let response = try await request(opcode: 51, payload: payload)
        guard let raw = response["chat"] as? [String: Any] else { throw APIError.missingField("chat") }
        return Chat(from: raw)
    }

    func deleteChat(chatId: Int) async throws {
        try await sendMessage(opcode: 53, payload: ["chatId": chatId])
    }

    func searchChats(query: String) async throws -> [Chat] {
        let response = try await request(opcode: 54, payload: ["query": query])
        return (response["chats"] as? [[String: Any]] ?? []).map { Chat(from: $0) }
    }

    // MARK: - Messages

    func fetchMessages(chatId: Int, limit: Int = 50, beforeId: String? = nil) async throws -> [Message] {
        var payload: [String: Any] = ["chatId": chatId, "limit": limit]
        if let id = beforeId { payload["beforeId"] = id }
        let response = try await request(opcode: 60, payload: payload)
        let rawMessages = response["messages"] as? [[String: Any]] ?? []
        return rawMessages.map { Message(from: $0) }
    }

    func sendMessage(
        chatId: Int,
        text: String,
        replyToId: String? = nil,
        forwardFromId: String? = nil,
        attachments: [[String: Any]] = []
    ) async throws -> Message {
        var payload: [String: Any] = ["chatId": chatId, "text": text]
        if let rid = replyToId { payload["replyTo"] = ["id": rid, "type": "REPLY"] }
        if let fid = forwardFromId { payload["forwardFrom"] = fid }
        if !attachments.isEmpty { payload["attaches"] = attachments }

        let response = try await request(opcode: 61, payload: payload)
        guard let raw = response["message"] as? [String: Any] else {
            throw APIError.missingField("message")
        }
        return Message(from: raw)
    }

    func editMessage(messageId: String, chatId: Int, newText: String) async throws {
        try await sendMessage(opcode: 62, payload: ["id": messageId, "chatId": chatId, "text": newText])
    }

    func deleteMessage(messageId: String, chatId: Int) async throws {
        try await sendMessage(opcode: 63, payload: ["id": messageId, "chatId": chatId])
    }

    func markRead(chatId: Int, messageId: String) async throws {
        try await sendMessage(opcode: 64, payload: ["chatId": chatId, "messageId": messageId])
    }

    func pinMessage(messageId: String, chatId: Int) async throws {
        try await sendMessage(opcode: 65, payload: ["id": messageId, "chatId": chatId])
    }

    func sendReaction(messageId: String, chatId: Int, emoji: String) async throws {
        try await sendMessage(opcode: 66, payload: ["id": messageId, "chatId": chatId, "emoji": emoji])
    }

    // MARK: - Folders

    func createFolder(title: String, chatIds: [Int]) async throws -> ChatFolder {
        let response = try await request(opcode: 56, payload: ["title": title, "chatIds": chatIds])
        guard let raw = response["folder"] as? [String: Any] else { throw APIError.missingField("folder") }
        return ChatFolder(from: raw)
    }

    func addChatsToFolder(folderId: Int, chatIds: [Int]) async throws {
        try await sendMessage(opcode: 57, payload: ["folderId": folderId, "chatIds": chatIds])
    }

    func removeChatsFromFolder(folderId: Int, chatIds: [Int]) async throws {
        try await sendMessage(opcode: 58, payload: ["folderId": folderId, "chatIds": chatIds])
    }
}

enum APIError: Error {
    case missingField(String)
    case serverError(String)
    case notConnected
}
