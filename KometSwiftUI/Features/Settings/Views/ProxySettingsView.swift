import SwiftUI

struct ProxySettingsView: View {
    @State private var config = ProxyConfiguration()

    var body: some View {
        Form {
            Section {
                Toggle(String(localized: "Enable Proxy"), isOn: $config.enabled)
            }
            if config.enabled {
                Section(String(localized: "Proxy Type")) {
                    Picker(String(localized: "Type"), selection: $config.proxyType) {
                        ForEach(ProxyConfiguration.ProxyType.allCases, id: \.self) {
                            Text($0.rawValue).tag($0)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                Section(String(localized: "Server")) {
                    TextField(String(localized: "Host"), text: $config.host)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                    TextField(String(localized: "Port"), value: $config.port, format: .number)
                        .keyboardType(.numberPad)
                }
                Section(String(localized: "Authentication (optional)")) {
                    TextField(String(localized: "Username"), text: $config.username)
                    SecureField(String(localized: "Password"), text: $config.password)
                }
            }
        }
        .navigationTitle(String(localized: "Proxy"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(String(localized: "Save")) {
                    Task { await ProxyService.shared.saveConfig(config) }
                }
                .fontWeight(.semibold)
            }
        }
        .task {
            config = await ProxyService.shared.currentConfig() ?? ProxyConfiguration()
        }
    }
}
