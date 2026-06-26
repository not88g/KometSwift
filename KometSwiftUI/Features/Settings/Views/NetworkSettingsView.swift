import SwiftUI

struct NetworkSettingsView: View {
    @State private var connectionLog: [String] = []
    @State private var isConnected = false

    var body: some View {
        Form {
            Section(String(localized: "Status")) {
                HStack {
                    Text(String(localized: "Connection"))
                    Spacer()
                    Text(isConnected ? String(localized: "Connected") : String(localized: "Disconnected"))
                        .foregroundStyle(isConnected ? .green : .red)
                }
                HStack {
                    Text(String(localized: "Server"))
                    Spacer()
                    Text(AppConstants.apiHost).foregroundStyle(.secondary)
                }
            }

            Section(String(localized: "Actions")) {
                Button(String(localized: "Force reconnect")) {
                    Task {
                        await ConnectionManager.shared.disconnect()
                        await ConnectionManager.shared.connect()
                    }
                }
                NavigationLink(value: NavigationDestination.proxySettings) {
                    Text(String(localized: "Proxy settings"))
                }
                NavigationLink(value: NavigationDestination.socketLog) {
                    Text(String(localized: "Socket log"))
                }
            }
        }
        .navigationTitle(String(localized: "Network"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: NavigationDestination.self) {
            AppNavigationStack.view(for: $0)
        }
    }
}
