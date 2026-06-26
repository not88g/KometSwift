// Media upload/download API — mirrors api_service_media.dart.

import Foundation
import UIKit

extension APIService {

    // MARK: - Avatar

    func fetchAvatar(baseUrl: String, size: Int = 200) -> URL? {
        URL(string: "\(baseUrl)/\(size)")
    }

    func uploadAvatar(image: UIImage) async throws -> String {
        guard let jpeg = image.jpegData(compressionQuality: 0.85) else {
            throw APIError.serverError("Failed to encode image")
        }
        let response = try await uploadData(jpeg, mimeType: "image/jpeg", opcode: 90)
        return response["baseUrl"] as? String ?? ""
    }

    // MARK: - File upload

    func uploadFile(data: Data, name: String, mimeType: String) async throws -> [String: Any] {
        return try await uploadData(data, mimeType: mimeType, opcode: 91, extra: ["name": name])
    }

    func uploadAudio(data: Data) async throws -> [String: Any] {
        return try await uploadData(data, mimeType: "audio/ogg", opcode: 92)
    }

    // MARK: - Download

    func downloadFile(url: URL) async throws -> Data {
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    }

    func fetchChatMedia(chatId: Int, type: String = "IMAGE") async throws -> [[String: Any]] {
        let response = try await request(opcode: 93, payload: ["chatId": chatId, "type": type])
        return response["media"] as? [[String: Any]] ?? []
    }

    // MARK: - Internal

    private func uploadData(
        _ data: Data, mimeType: String, opcode: UInt16, extra: [String: Any] = [:]
    ) async throws -> [String: Any] {
        // Encode binary payload inline in MsgPack frame
        var payload: [String: Any] = ["data": data, "mimeType": mimeType]
        payload.merge(extra) { $1 }
        return try await request(opcode: opcode, payload: payload)
    }
}
