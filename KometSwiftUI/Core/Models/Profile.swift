import Foundation

struct Profile: Codable, Equatable {
    let id: Int
    let firstName: String
    let lastName: String
    let name: String
    let photoBaseUrl: String?
    let description: String?
    let phone: String?

    var displayName: String { name.isEmpty ? "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces) : name }

    init(from raw: [String: Any]) {
        self.id = raw["id"] as? Int ?? 0
        self.firstName = raw["firstName"] as? String ?? ""
        self.lastName = raw["lastName"] as? String ?? ""
        let fn = self.firstName
        let ln = self.lastName
        self.name = raw["name"] as? String ?? "\(fn) \(ln)".trimmingCharacters(in: .whitespaces)
        self.photoBaseUrl = raw["baseUrl"] as? String ?? raw["photoBaseUrl"] as? String
        self.description = raw["description"] as? String
        self.phone = raw["phone"] as? String
    }
}
