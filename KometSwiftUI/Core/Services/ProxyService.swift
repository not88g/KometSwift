// SOCKS5 / HTTP proxy support — mirrors lib/utils/proxy_service.dart.

import Foundation
import Network

struct ProxyConfiguration: Codable {
    var enabled: Bool = false
    var host: String = ""
    var port: UInt16 = 1080
    var username: String = ""
    var password: String = ""
    var proxyType: ProxyType = .socks5

    enum ProxyType: String, Codable, CaseIterable {
        case socks5 = "SOCKS5"
        case http   = "HTTP"
    }
}

actor ProxyService {
    static let shared = ProxyService()

    private let key = "komet.proxyConfig"

    func currentConfig() async -> ProxyConfiguration? {
        guard let data = UserDefaults.standard.data(forKey: key),
              let config = try? JSONDecoder().decode(ProxyConfiguration.self, from: data),
              config.enabled, !config.host.isEmpty
        else { return nil }
        return config
    }

    func saveConfig(_ config: ProxyConfiguration) {
        let data = try? JSONEncoder().encode(config)
        UserDefaults.standard.set(data, forKey: key)
    }

    func makeURLSessionConfiguration(proxy: ProxyConfiguration) -> URLSessionConfiguration {
        let config = URLSessionConfiguration.default
        if proxy.proxyType == .http {
            config.connectionProxyDictionary = [
                kCFNetworkProxiesHTTPEnable as String:  true,
                kCFNetworkProxiesHTTPProxy as String:   proxy.host,
                kCFNetworkProxiesHTTPPort as String:    proxy.port,
            ]
        }
        // SOCKS5 is handled at NWConnection level in ConnectionManager
        return config
    }
}
