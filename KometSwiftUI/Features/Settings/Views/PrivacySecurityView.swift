import SwiftUI

struct PrivacySecurityView: View {
    var body: some View {
        List {
            NavigationLink(value: NavigationDestination.privacySettings) {
                Label(String(localized: "Privacy"), systemImage: "hand.raised")
            }
            NavigationLink(value: NavigationDestination.securitySettings) {
                Label(String(localized: "Security"), systemImage: "lock.shield")
            }
        }
        .navigationTitle(String(localized: "Privacy & Security"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: NavigationDestination.self) {
            AppNavigationStack.view(for: $0)
        }
    }
}

struct PrivacySettingsView: View {
    @State private var lastSeenMode = "everyone"

    var body: some View {
        Form {
            Section(String(localized: "Last Seen")) {
                Picker(String(localized: "Who can see"), selection: $lastSeenMode) {
                    Text(String(localized: "Everyone")).tag("everyone")
                    Text(String(localized: "Nobody")).tag("nobody")
                }
            }
        }
        .navigationTitle(String(localized: "Privacy"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SecuritySettingsView: View {
    @State private var twoFactorEnabled = false

    var body: some View {
        Form {
            Section(String(localized: "Two-factor authentication")) {
                Toggle(String(localized: "Enable"), isOn: $twoFactorEnabled)
            }
        }
        .navigationTitle(String(localized: "Security"))
        .navigationBarTitleDisplayMode(.inline)
    }
}
