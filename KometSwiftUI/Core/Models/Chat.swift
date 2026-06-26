import Foundation

struct Chat: Identifiable, Codable, Equatable {
    let id: Int
    let ownerId: Int
    let lastMessage: Message
    let participantIds: [Int]
    let newMessages: Int
    let title: String?
    let type: String?
    let baseIconUrl: String?
    let description: String?
    let participantsCount: Int?
    let pinnedMessage: Message?

    init(from raw: [String: Any]) {
        self.id = raw["id"] as? Int ?? 0
        self.ownerId = raw["owner"] as? Int ?? 0

        let participants = raw["participants"] as? [String: Any] ?? [:]
        self.participantIds = participants.keys.compactMap { Int($0) }

        if let lm = raw["lastMessage"] as? [String: Any] {
            self.lastMessage = Message(from: lm)
        } else {
            self.lastMessage = Message(
                id: "empty", text: "", time: Int(Date().timeIntervalSince1970 * 1000), senderId: 0
            )
        }

        if let pm = raw["pinnedMessage"] as? [String: Any] {
            self.pinnedMessage = Message(from: pm)
        } else {
            self.pinnedMessage = nil
        }

        self.newMessages = raw["newMessages"] as? Int ?? 0
        self.title = raw["title"] as? String
        self.type = raw["type"] as? String
        self.baseIconUrl = raw["baseIconUrl"] as? String
        self.description = raw["description"] as? String
        self.participantsCount = raw["participantsCount"] as? Int
    }

    init(
        id: Int, ownerId: Int, lastMessage: Message, participantIds: [Int],
        newMessages: Int, title: String? = nil, type: String? = nil,
        baseIconUrl: String? = nil, description: String? = nil,
        participantsCount: Int? = nil, pinnedMessage: Message? = nil
    ) {
        self.id = id; self.ownerId = ownerId; self.lastMessage = lastMessage
        self.participantIds = participantIds; self.newMessages = newMessages
        self.title = title; self.type = type; self.baseIconUrl = baseIconUrl
        self.description = description; self.participantsCount = participantsCount
        self.pinnedMessage = pinnedMessage
    }

    var isGroup: Bool { type == "CHAT" || participantIds.count > 2 }

    var displayTitle: String {
        if let t = title, !t.isEmpty { return t }
        if isGroup { return String(localized: "Group \(participantIds.count)") }
        return String(localized: "Chat")
    }

    func copyWith(
        lastMessage: Message? = nil,
        newMessages: Int? = nil,
        title: String? = nil,
        pinnedMessage: Message? = nil
    ) -> Chat {
        Chat(
            id: id, ownerId: ownerId,
            lastMessage: lastMessage ?? self.lastMessage,
            participantIds: participantIds,
            newMessages: newMessages ?? self.newMessages,
            title: title ?? self.title,
            type: type, baseIconUrl: baseIconUrl,
            description: description,
            participantsCount: participantsCount,
            pinnedMessage: pinnedMessage ?? self.pinnedMessage
        )
    }
}
