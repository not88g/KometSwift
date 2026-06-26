// Push notification service — mirrors services/notification_service.dart.

import Foundation
import UserNotifications
import UIKit

actor NotificationService: NSObject {
    static let shared = NotificationService()

    private var pushToken: String?

    func initialize() async {
        let center = UNUserNotificationCenter.current()
        _ = try? await center.requestAuthorization(options: [.alert, .badge, .sound])
        await MainActor.run { UIApplication.shared.registerForRemoteNotifications() }
    }

    func handlePushToken(_ tokenData: Data) {
        pushToken = tokenData.map { String(format: "%02.2hhx", $0) }.joined()
        Task { await registerToken() }
    }

    private func registerToken() async {
        guard let token = pushToken else { return }
        try? await APIService.shared.sendMessage(opcode: 120, payload: [
            "platform": "APNS",
            "token":    token,
        ])
    }

    // MARK: - Local notification

    func showLocal(title: String, body: String, chatId: Int? = nil) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body  = body
        content.sound = .default
        if let cid = chatId {
            content.userInfo = ["chatId": cid]
        }
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        try? await UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Notification settings per chat

    func isMuted(chatId: Int) -> Bool {
        UserDefaults.standard.bool(forKey: "muted_\(chatId)")
    }

    func setMuted(_ muted: Bool, chatId: Int) {
        UserDefaults.standard.set(muted, forKey: "muted_\(chatId)")
    }
}
