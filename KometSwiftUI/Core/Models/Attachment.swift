import Foundation

enum AttachmentType: String, Codable {
    case image = "IMAGE"
    case video = "VIDEO"
    case audio = "AUDIO"
    case file = "FILE"
    case call = "CALL"
    case sticker = "STICKER"
    case unknown
}

struct Attachment: Identifiable, Codable {
    let id: String
    let type: AttachmentType
    let url: String?
    let name: String?
    let size: Int?
    let duration: Int?
    let width: Int?
    let height: Int?
    let mimeType: String?

    init(from raw: [String: Any]) {
        self.id = raw["id"] as? String ?? UUID().uuidString
        let typeStr = raw["_type"] as? String ?? raw["type"] as? String ?? ""
        self.type = AttachmentType(rawValue: typeStr) ?? .unknown
        self.url = raw["url"] as? String ?? raw["baseUrl"] as? String
        self.name = raw["name"] as? String
        self.size = raw["size"] as? Int
        self.duration = raw["duration"] as? Int
        self.width = raw["width"] as? Int
        self.height = raw["height"] as? Int
        self.mimeType = raw["mimeType"] as? String
    }
}

struct CallAttachment: Codable {
    let duration: Int?
    let status: String?
    let initiatorId: Int?

    var isMissed: Bool { status == "MISSED" }
    var formattedDuration: String {
        guard let d = duration else { return "" }
        let m = d / 60, s = d % 60
        return String(format: "%d:%02d", m, s)
    }
}
