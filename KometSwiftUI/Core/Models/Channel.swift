import Foundation

struct Channel: Identifiable, Codable, Equatable {
    let id: Int
    let title: String
    let description: String?
    let baseIconUrl: String?
    let participantsCount: Int
    let isSubscribed: Bool

    init(from raw: [String: Any]) {
        self.id = raw["id"] as? Int ?? 0
        self.title = raw["title"] as? String ?? ""
        self.description = raw["description"] as? String
        self.baseIconUrl = raw["baseIconUrl"] as? String
        self.participantsCount = raw["participantsCount"] as? Int ?? 0
        self.isSubscribed = raw["isSubscribed"] as? Bool ?? false
    }
}
