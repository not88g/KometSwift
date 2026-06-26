// Mirrors deep link handling from home_screen.dart (app_links).
// Handles: komet:// scheme, https://max.ru/join/... invite links, https://max.ru/id... user IDs.

import UIKit

final class DeepLinkHandler {
    static let shared = DeepLinkHandler()

    private weak var appState: AppState?

    // Navigation is performed by posting to the ChatsViewModel via a global subject
    // so this handler doesn't need a direct reference to the navigation stack.
    private var pendingChatId: Int?

    func handle(_ url: URL, appState: AppState? = nil) {
        self.appState = appState ?? self.appState

        let absoluteString = url.absoluteString

        // Join group link: https://max.ru/join/<token>
        if absoluteString.contains("max.ru/join/") {
            let token = url.lastPathComponent
            Task { await handleJoinLink(token) }
            return
        }

        // User ID link: https://max.ru/id<number>
        if absoluteString.contains("max.ru/id") {
            let idStr = absoluteString.replacingOccurrences(of: ".*/id", with: "", options: .regularExpression)
            if let userId = Int(idStr) {
                openChat(userId)
            }
            return
        }

        // Custom komet:// scheme
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            switch components.host {
            case "chat":
                if let idStr = components.queryItems?.first(where: { $0.name == "id" })?.value,
                   let id = Int(idStr) {
                    openChat(id)
                }
            default:
                break
            }
        }
    }

    func openChat(_ chatId: Int) {
        pendingChatId = chatId
        NotificationCenter.default.post(name: .openChat, object: chatId)
    }

    private func handleJoinLink(_ token: String) async {
        do {
            let link = AppConstants.joinLinkPrefix + token
            let chat = try await APIService.shared.joinGroupByLink(link: link)
            await MainActor.run { openChat(chat.id) }
        } catch {}
    }
}

extension Notification.Name {
    static let openChat = Notification.Name("komet.openChat")
}

// MARK: - App constants (mirrors app_urls.dart)

enum AppConstants {
    static let websocketUrls = [
        "wss://ws-api.oneme.ru:443/websocket",
        "wss://ws-api.oneme.ru/websocket",
        "wss://ws-api.oneme.ru:8443/websocket",
        "ws://ws-api.oneme.ru:80/websocket",
    ]
    static let apiHost      = "api.oneme.ru"
    static let apiPort: UInt16 = 443
    static let webOrigin    = "https://web.max.ru"
    static let legalUrl     = "https://legal.max.ru/ps"
    static let telegramChannel = "https://t.me/TeamKomet"
    static let joinLinkPrefix  = "https://max.ru/join/"
    static let idLinkPrefix    = "https://max.ru/id"
    static let whitelistUrl    = "https://wl.liarts.ru/wl"
}
