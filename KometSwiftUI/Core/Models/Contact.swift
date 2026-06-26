import Foundation

struct Contact: Identifiable, Codable, Equatable {
    let id: Int
    let name: String
    let firstName: String
    let lastName: String
    let description: String?
    let photoBaseUrl: String?
    let isBlocked: Bool
    let isBlockedByMe: Bool
    let accountStatus: Int
    let status: String?
    let options: [String]

    var isBot: Bool { options.contains("BOT") }
    var isUserBlocked: Bool { isBlockedByMe || isBlocked }
    var isOnline: Bool { accountStatus == 1 }

    init(from raw: [String: Any]) {
        let userId = raw["id"] as? Int ?? 0
        let nameData = (raw["names"] as? [[String: Any]])?.first

        let fn = nameData?["firstName"] as? String ?? ""
        let ln = nameData?["lastName"] as? String ?? ""
        let full = "\(fn) \(ln)".trimmingCharacters(in: .whitespaces)
        let computed = !full.isEmpty ? full : (nameData?["name"] as? String ?? "ID \(userId)")

        self.id = userId
        self.name = computed
        self.firstName = fn
        self.lastName = ln
        self.description = raw["description"] as? String
        self.photoBaseUrl = raw["baseUrl"] as? String
        self.accountStatus = raw["accountStatus"] as? Int ?? 0
        self.status = raw["status"] as? String
        self.options = raw["options"] as? [String] ?? []
        self.isBlocked = self.status == "BLOCKED"
        self.isBlockedByMe = self.status == "BLOCKED"
    }

    init(
        id: Int, name: String, firstName: String, lastName: String,
        description: String? = nil, photoBaseUrl: String? = nil,
        isBlocked: Bool = false, isBlockedByMe: Bool = false,
        accountStatus: Int = 0, status: String? = nil, options: [String] = []
    ) {
        self.id = id; self.name = name; self.firstName = firstName; self.lastName = lastName
        self.description = description; self.photoBaseUrl = photoBaseUrl
        self.isBlocked = isBlocked; self.isBlockedByMe = isBlockedByMe
        self.accountStatus = accountStatus; self.status = status; self.options = options
    }
}
