import Foundation

struct Account: Identifiable, Codable, Equatable {
    let id: String
    let token: String
    let userId: Int
    let displayName: String
    let avatarUrl: String?
    let createdAt: Date

    init(id: String = UUID().uuidString, token: String, userId: Int,
         displayName: String, avatarUrl: String? = nil, createdAt: Date = Date()) {
        self.id = id; self.token = token; self.userId = userId
        self.displayName = displayName; self.avatarUrl = avatarUrl; self.createdAt = createdAt
    }
}
