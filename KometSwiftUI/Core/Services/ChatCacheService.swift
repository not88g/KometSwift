// Mirrors services/chat_cache_service.dart.

import Foundation

actor ChatCacheService {
    static let shared = ChatCacheService()

    private var chats: [Chat] = []
    private var messages: [Int: [Message]] = [:]

    func initialize() async {
        chats    = await CacheService.shared.load([Chat].self,    forKey: "chats") ?? []
        messages = await CacheService.shared.load([Int: [Message]].self, forKey: "messages") ?? [:]
    }

    // MARK: - Chats

    func cachedChats() -> [Chat] { chats }

    func storeChats(_ newChats: [Chat]) async {
        chats = newChats
        await CacheService.shared.store(newChats, forKey: "chats")
    }

    func upsertChat(_ chat: Chat) async {
        if let idx = chats.firstIndex(where: { $0.id == chat.id }) {
            chats[idx] = chat
        } else {
            chats.insert(chat, at: 0)
        }
        await CacheService.shared.store(chats, forKey: "chats")
    }

    // MARK: - Messages

    func messages(for chatId: Int) -> [Message] { messages[chatId] ?? [] }

    func store(messages newMessages: [Message], for chatId: Int) async {
        messages[chatId] = newMessages
        await CacheService.shared.store(messages, forKey: "messages")
    }

    func upsertMessage(_ message: Message, for chatId: Int) async {
        var list = messages[message.cid ?? chatId] ?? []
        if let idx = list.firstIndex(where: { $0.id == message.id }) {
            list[idx] = message
        } else {
            list.append(message)
        }
        messages[message.cid ?? chatId] = list
    }

    func clearAll() async {
        chats = []
        messages = [:]
        await CacheService.shared.remove(forKey: "chats")
        await CacheService.shared.remove(forKey: "messages")
    }
}
