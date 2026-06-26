// Offline message queue — mirrors services/message_queue_service.dart.
// Queued messages are persisted to disk and resent on reconnection.

import Foundation

struct QueuedMessage: Codable, Identifiable {
    let id: String
    let chatId: Int
    let text: String
    let replyToId: String?
    let createdAt: Date

    init(chatId: Int, text: String, replyToId: String? = nil) {
        self.id = UUID().uuidString
        self.chatId = chatId
        self.text = text
        self.replyToId = replyToId
        self.createdAt = Date()
    }
}

actor MessageQueueService {
    static let shared = MessageQueueService()

    private let persistenceKey = "komet.messageQueue"
    private var queue: [QueuedMessage] = []

    func initialize() async {
        queue = load()
    }

    func enqueue(chatId: Int, text: String, replyToId: String? = nil) async {
        let msg = QueuedMessage(chatId: chatId, text: text, replyToId: replyToId)
        queue.append(msg)
        persist()
    }

    func flushQueue() async {
        guard !queue.isEmpty else { return }
        var remaining: [QueuedMessage] = []
        for queued in queue {
            do {
                _ = try await APIService.shared.sendMessage(
                    chatId: queued.chatId,
                    text: queued.text,
                    replyToId: queued.replyToId
                )
            } catch {
                remaining.append(queued)
            }
        }
        queue = remaining
        persist()
    }

    func pendingCount(for chatId: Int) -> Int {
        queue.filter { $0.chatId == chatId }.count
    }

    private func load() -> [QueuedMessage] {
        guard let data = UserDefaults.standard.data(forKey: persistenceKey),
              let decoded = try? JSONDecoder().decode([QueuedMessage].self, from: data)
        else { return [] }
        return decoded
    }

    private func persist() {
        let data = try? JSONEncoder().encode(queue)
        UserDefaults.standard.set(data, forKey: persistenceKey)
    }
}
