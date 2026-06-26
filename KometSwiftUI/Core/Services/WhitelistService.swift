// Whitelist validation — mirrors services/whitelist_service.dart.
// Only used in tester builds; checks wl.liarts.ru/wl.

import Foundation

actor WhitelistService {
    static let shared = WhitelistService()

    private let checkUrl = "https://wl.liarts.ru/wl"
    private let localKey = "whitelist.json"

    func initialize() async {
        // Load local whitelist.json bundled with the app
    }

    func validate() async {
        guard let url = URL(string: checkUrl) else { return }
        guard let token = await TokenStore.shared.loadToken() else { return }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        _ = try? await URLSession.shared.data(for: request)
    }

    // For local (bundled) whitelist check
    func isAllowed(userId: Int) -> Bool {
        // In production builds this always returns true
        true
    }
}
