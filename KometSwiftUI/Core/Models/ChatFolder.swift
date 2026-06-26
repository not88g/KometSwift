import Foundation

struct ChatFolder: Identifiable, Codable, Equatable {
    let id: Int
    let title: String
    let chatIds: [Int]
    let order: Int

    init(from raw: [String: Any]) {
        self.id = raw["id"] as? Int ?? 0
        self.title = raw["title"] as? String ?? ""
        self.chatIds = raw["chatIds"] as? [Int] ?? []
        self.order = raw["order"] as? Int ?? 0
    }

    init(id: Int, title: String, chatIds: [Int], order: Int) {
        self.id = id; self.title = title; self.chatIds = chatIds; self.order = order
    }
}
