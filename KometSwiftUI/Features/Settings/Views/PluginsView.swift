import SwiftUI

struct PluginsView: View {
    private let pluginService = PluginService.shared

    var body: some View {
        List {
            if pluginService.plugins.isEmpty {
                ContentUnavailableView(
                    String(localized: "No plugins installed"),
                    systemImage: "puzzlepiece.extension",
                    description: Text(String(localized: "Plugins extend Komet's functionality"))
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(pluginService.plugins) { plugin in
                    NavigationLink(value: NavigationDestination.pluginSection(pluginId: plugin.id)) {
                        HStack {
                            Image(systemName: "puzzlepiece.extension")
                                .foregroundStyle(.kometAccent)
                            VStack(alignment: .leading) {
                                Text(plugin.displayName).font(.kometHeadline)
                                Text(plugin.version).font(.kometCaption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { plugin.isEnabled },
                                set: { v in pluginService.setEnabled(v, pluginId: plugin.id) }
                            ))
                            .labelsHidden()
                        }
                    }
                }
            }
        }
        .navigationTitle(String(localized: "Plugins"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: NavigationDestination.self) {
            AppNavigationStack.view(for: $0)
        }
    }
}

struct PluginSectionView: View {
    let pluginId: String

    var body: some View {
        Text(String(localized: "Plugin: \(pluginId)"))
            .navigationTitle(pluginId)
    }
}
