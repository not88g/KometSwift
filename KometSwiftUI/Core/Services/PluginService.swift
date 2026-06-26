// Plugin system — mirrors plugins/plugin_service.dart.
// Swift plugin protocol; plugins are Swift modules loaded at launch.

import Foundation
import Observation

protocol KometPlugin: AnyObject {
    var id: String { get }
    var displayName: String { get }
    var version: String { get }
    var isEnabled: Bool { get set }
    func activate()
    func deactivate()
}

struct PluginInfo: Identifiable, Codable {
    let id: String
    let displayName: String
    let version: String
    var isEnabled: Bool
}

@Observable
final class PluginService {
    static let shared = PluginService()

    private(set) var plugins: [PluginInfo] = []
    private var activePlugins: [String: any KometPlugin] = [:]

    func initialize() async {
        // Load registered plugins (statically linked in Swift)
        // Dynamic plugin loading would require code signing entitlements
        plugins = loadStoredPluginStates()
    }

    func register(plugin: any KometPlugin) {
        activePlugins[plugin.id] = plugin
        if !plugins.contains(where: { $0.id == plugin.id }) {
            plugins.append(PluginInfo(
                id: plugin.id, displayName: plugin.displayName,
                version: plugin.version, isEnabled: plugin.isEnabled
            ))
        }
    }

    func setEnabled(_ enabled: Bool, pluginId: String) {
        if let idx = plugins.firstIndex(where: { $0.id == pluginId }) {
            plugins[idx].isEnabled = enabled
            if enabled { activePlugins[pluginId]?.activate() }
            else       { activePlugins[pluginId]?.deactivate() }
            persistPluginStates()
        }
    }

    private func loadStoredPluginStates() -> [PluginInfo] {
        guard let data = UserDefaults.standard.data(forKey: "komet.plugins"),
              let decoded = try? JSONDecoder().decode([PluginInfo].self, from: data)
        else { return [] }
        return decoded
    }

    private func persistPluginStates() {
        let data = try? JSONEncoder().encode(plugins)
        UserDefaults.standard.set(data, forKey: "komet.plugins")
    }
}
