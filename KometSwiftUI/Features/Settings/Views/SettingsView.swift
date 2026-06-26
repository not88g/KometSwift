import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @State private var profile: Profile?

    var body: some View {
        List {
            // Profile header
            if let profile {
                Section {
                    NavigationLink(value: NavigationDestination.userProfile(userId: profile.id)) {
                        HStack(spacing: KometSpacing.md) {
                            AvatarView(baseUrl: profile.photoBaseUrl, displayName: profile.displayName,
                                       size: KometSpacing.avatarSizeLg)
                            VStack(alignment: .leading) {
                                Text(profile.displayName).font(.kometHeadline)
                                Text(String(localized: "View profile")).font(.kometCaption).foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, KometSpacing.xs)
                    }
                }
            }

            Section(String(localized: "Appearance")) {
                navRow(icon: "paintbrush",      label: String(localized: "Appearance"),       dest: .appearanceSettings)
                navRow(icon: "bell",             label: String(localized: "Notifications"),    dest: .notificationSettings)
            }

            Section(String(localized: "Privacy & Security")) {
                navRow(icon: "hand.raised",      label: String(localized: "Privacy"),          dest: .privacySecurity)
                navRow(icon: "lock.shield",      label: String(localized: "Security"),         dest: .securitySettings)
                navRow(icon: "key",              label: String(localized: "Auth method"),      dest: .authSettings)
                navRow(icon: "list.bullet",      label: String(localized: "Active sessions"),  dest: .sessions)
                navRow(icon: "qrcode",           label: String(localized: "QR Login"),         dest: .qrLogin)
            }

            Section(String(localized: "Network")) {
                navRow(icon: "network",          label: String(localized: "Network"),          dest: .networkSettings)
                navRow(icon: "arrow.triangle.2.circlepath", label: String(localized: "Reconnection"), dest: .reconnectionSettings)
                navRow(icon: "server.rack",      label: String(localized: "Proxy"),            dest: .proxySettings)
                navRow(icon: "terminal",         label: String(localized: "Socket log"),       dest: .socketLog)
            }

            Section(String(localized: "Advanced")) {
                navRow(icon: "person.badge.shield.checkmark", label: String(localized: "Session spoofing"), dest: .sessionSpoofing)
                navRow(icon: "puzzlepiece",      label: String(localized: "Plugins"),          dest: .plugins)
                navRow(icon: "externaldrive",    label: String(localized: "Storage"),          dest: .storage)
                navRow(icon: "internaldrive",    label: String(localized: "Cache"),            dest: .cacheManagement)
                navRow(icon: "person.2",         label: String(localized: "Accounts"),         dest: .manageAccount)
                navRow(icon: "wrench.and.screwdriver", label: String(localized: "Debug"),      dest: .debug)
            }

            Section {
                navRow(icon: "info.circle",      label: String(localized: "About Komet"),      dest: .about)
                Button(role: .destructive) {
                    Task { await appState.signOut() }
                } label: {
                    Label(String(localized: "Sign out"), systemImage: "door.left.hand.open")
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle(String(localized: "Settings"))
        .navigationDestination(for: NavigationDestination.self) {
            AppNavigationStack.view(for: $0)
        }
        .task {
            profile = try? await APIService.shared.fetchProfile()
        }
    }

    private func navRow(icon: String, label: String, dest: NavigationDestination) -> some View {
        NavigationLink(value: dest) {
            Label(label, systemImage: icon)
        }
    }
}
