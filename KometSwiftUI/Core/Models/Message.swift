import Foundation

struct Message: Identifiable, Codable, Equatable {
    let id: String
    let text: String
    let time: Int
    let senderId: Int
    let status: String?
    let updateTime: Int?
    let attaches: [[String: AnyCodable]]
    let cid: Int?
    let reactionInfo: [String: AnyCodable]?
    let link: [String: AnyCodable]?
    let elements: [[String: AnyCodable]]
    let isDeleted: Bool
    let originalText: String?

    init(
        id: String,
        text: String,
        time: Int,
        senderId: Int,
        status: String? = nil,
        updateTime: Int? = nil,
        attaches: [[String: AnyCodable]] = [],
        cid: Int? = nil,
        reactionInfo: [String: AnyCodable]? = nil,
        link: [String: AnyCodable]? = nil,
        elements: [[String: AnyCodable]] = [],
        isDeleted: Bool = false,
        originalText: String? = nil
    ) {
        self.id = id
        self.text = text
        self.time = time
        self.senderId = senderId
        self.status = status
        self.updateTime = updateTime
        self.attaches = attaches
        self.cid = cid
        self.reactionInfo = reactionInfo
        self.link = link
        self.elements = elements
        self.isDeleted = isDeleted
        self.originalText = originalText
    }

    init(from raw: [String: Any]) {
        let senderId: Int
        if let s = raw["sender"] as? Int { senderId = s } else { senderId = 0 }
        let time: Int
        if let t = raw["time"] as? Int { time = t } else { time = 0 }

        self.id = (raw["id"].map { "\($0)" }) ?? "local_\(Date().timeIntervalSince1970)"
        self.text = raw["text"] as? String ?? ""
        self.time = time
        self.senderId = senderId
        self.status = raw["status"] as? String
        self.updateTime = raw["updateTime"] as? Int
        self.attaches = (raw["attaches"] as? [[String: Any]] ?? []).map { $0.mapValues { AnyCodable($0) } }
        self.cid = raw["cid"] as? Int
        self.reactionInfo = (raw["reactionInfo"] as? [String: Any])?.mapValues { AnyCodable($0) }
        self.link = (raw["link"] as? [String: Any])?.mapValues { AnyCodable($0) }
        self.elements = (raw["elements"] as? [[String: Any]] ?? []).map { $0.mapValues { AnyCodable($0) } }
        self.isDeleted = raw["isDeleted"] as? Bool ?? false
        self.originalText = raw["originalText"] as? String
    }

    // MARK: - Computed

    var isEdited: Bool { status == "EDITED" }
    var isReply: Bool { link?["type"]?.value as? String == "REPLY" }
    var isForwarded: Bool { link?["type"]?.value as? String == "FORWARD" }
    var hasFileAttach: Bool {
        attaches.contains { ($0["_type"]?.value as? String ?? $0["type"]?.value as? String) == "FILE" }
    }

    func canEdit(currentUserId: Int) -> Bool {
        guard !isDeleted, senderId == currentUserId, attaches.isEmpty else { return false }
        let hoursSince = (Double(Date().timeIntervalSince1970 * 1000) - Double(time)) / (1000 * 60 * 60)
        return hoursSince <= 24
    }

    var formattedTime: String {
        let date = Date(timeIntervalSince1970: Double(time) / 1000)
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    var formattedDate: String {
        let date = Date(timeIntervalSince1970: Double(time) / 1000)
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return formattedTime }
        if calendar.isDateInYesterday(date) { return String(localized: "Yesterday") }
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM"
        return formatter.string(from: date)
    }

    func copyWith(
        text: String? = nil,
        status: String? = nil,
        isDeleted: Bool? = nil
    ) -> Message {
        Message(
            id: id, text: text ?? self.text, time: time, senderId: senderId,
            status: status ?? self.status, updateTime: updateTime,
            attaches: attaches, cid: cid, reactionInfo: reactionInfo,
            link: link, elements: elements, isDeleted: isDeleted ?? self.isDeleted,
            originalText: originalText
        )
    }
}

// MARK: - AnyCodable helper for heterogeneous dictionaries

struct AnyCodable: Codable, Equatable {
    let value: Any

    init(_ value: Any) { self.value = value }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let v = try? container.decode(Bool.self)   { self.value = v; return }
        if let v = try? container.decode(Int.self)    { self.value = v; return }
        if let v = try? container.decode(Double.self) { self.value = v; return }
        if let v = try? container.decode(String.self) { self.value = v; return }
        if let v = try? container.decode([AnyCodable].self) { self.value = v.map { $0.value }; return }
        if let v = try? container.decode([String: AnyCodable].self) { self.value = v.mapValues { $0.value }; return }
        self.value = NSNull()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let v as Bool:   try container.encode(v)
        case let v as Int:    try container.encode(v)
        case let v as Double: try container.encode(v)
        case let v as String: try container.encode(v)
        case let v as [Any]:  try container.encode(v.map { AnyCodable($0) })
        case let v as [String: Any]: try container.encode(v.mapValues { AnyCodable($0) })
        default: try container.encodeNil()
        }
    }

    static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        // Best-effort equality for primitive types
        switch (lhs.value, rhs.value) {
        case (let l as Bool,   let r as Bool):   return l == r
        case (let l as Int,    let r as Int):    return l == r
        case (let l as Double, let r as Double): return l == r
        case (let l as String, let r as String): return l == r
        default: return false
        }
    }
}
