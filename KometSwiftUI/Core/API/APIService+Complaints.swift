// Complaint/report API — mirrors api_service_complaints.dart.

import Foundation

enum ComplaintType: String, CaseIterable, Codable {
    case spam       = "SPAM"
    case harassment = "HARASSMENT"
    case violence   = "VIOLENCE"
    case adult      = "ADULT"
    case other      = "OTHER"

    var displayName: String {
        switch self {
        case .spam:       return String(localized: "Spam")
        case .harassment: return String(localized: "Harassment")
        case .violence:   return String(localized: "Violence")
        case .adult:      return String(localized: "Adult Content")
        case .other:      return String(localized: "Other")
        }
    }
}

struct ComplaintData {
    let type: ComplaintType
    let reason: String?
    let targetUserId: Int?
    let targetMessageId: String?
    let targetChatId: Int?
}

extension APIService {

    func sendComplaint(_ data: ComplaintData) async throws {
        var payload: [String: Any] = ["type": data.type.rawValue]
        if let r = data.reason         { payload["reason"] = r }
        if let uid = data.targetUserId { payload["userId"] = uid }
        if let mid = data.targetMessageId { payload["messageId"] = mid }
        if let cid = data.targetChatId { payload["chatId"] = cid }
        try await sendMessage(opcode: 110, payload: payload)
    }
}
