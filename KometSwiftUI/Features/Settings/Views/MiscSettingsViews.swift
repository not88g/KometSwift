// Remaining settings screens — AuthSettings, Reconnection, Bypass, ManageAccount,
// ChatEncryptionSettings, KometMisc.

import SwiftUI

// MARK: - Auth Settings

struct AuthSettingsView: View {
    var body: some View {
        Form {
            Section {
                NavigationLink(value: NavigationDestination.sessions) {
                    Label(String(localized: "Active sessions"), systemImage: "list.bullet")
                }
                NavigationLink(value: NavigationDestination.exportSession) {
                    Label(String(localized: "Export session"), systemImage: "square.and.arrow.up")
                }
                NavigationLink(value: NavigationDestination.qrLogin) {
                    Label(String(localized: "QR Login"), systemImage: "qrcode")
                }
                NavigationLink(value: NavigationDestination.tokenAuth) {
                    Label(String(localized: "Token auth"), systemImage: "key")
                }
            }
        }
        .navigationTitle(String(localized: "Auth Method"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: NavigationDestination.self) {
            AppNavigationStack.view(for: $0)
        }
    }
}

// MARK: - Reconnection Settings

struct ReconnectionSettingsView: View {
    @State private var maxRetries = 10
    @State private var baseDelay  = 3

    var body: some View {
        Form {
            Section(String(localized: "Retry")) {
                Stepper(String(localized: "Max retries: \(maxRetries)"), value: $maxRetries, in: 1...50)
                Stepper(String(localized: "Base delay: \(baseDelay)s"), value: $baseDelay, in: 1...60)
            }
        }
        .navigationTitle(String(localized: "Reconnection"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Bypass Settings

struct BypassView: View {
    @State private var bypassEnabled = false

    var body: some View {
        Form {
            Section(String(localized: "DPI Bypass")) {
                Toggle(String(localized: "Enable bypass"), isOn: $bypassEnabled)
            } footer: {
                Text(String(localized: "Experimental. May affect connection stability."))
            }
        }
        .navigationTitle(String(localized: "Bypass"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Manage Account

struct ManageAccountView: View {
    @State private var accounts: [Account] = []
    @Environment(AppState.self) private var appState

    var body: some View {
        List {
            ForEach(accounts) { account in
                HStack {
                    AvatarView(baseUrl: account.avatarUrl, displayName: account.displayName,
                               size: KometSpacing.avatarSizeMd)
                    VStack(alignment: .leading) {
                        Text(account.displayName).font(.kometHeadline)
                        Text("ID: \(account.userId)").font(.kometCaption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    if AccountManager.shared.currentAccount?.id == account.id {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.kometAccent)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    Task { await AccountManager.shared.switchTo(account) }
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        Task { await AccountManager.shared.removeAccount(account) }
                    } label: {
                        Label(String(localized: "Remove"), systemImage: "trash")
                    }
                }
            }

            Button {
                // Push phone entry for adding a second account
            } label: {
                Label(String(localized: "Add account"), systemImage: "plus.circle")
            }
        }
        .navigationTitle(String(localized: "Accounts"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { accounts = AccountManager.shared.accounts }
    }
}

// MARK: - Chat Encryption Settings

struct ChatEncryptionSettingsView: View {
    let chatId: Int
    @State private var enabled = false
    @State private var publicKey = ""

    var body: some View {
        Form {
            Section {
                Toggle(String(localized: "End-to-end encryption"), isOn: $enabled)
                    .onChange(of: enabled) { _, v in
                        ChatEncryptionService.shared.setEncryptionEnabled(v, for: chatId)
                    }
            } footer: {
                Text(String(localized: "Messages are encrypted before sending. Only you and the recipient can read them."))
            }

            if enabled {
                Section(String(localized: "Keys")) {
                    if !publicKey.isEmpty {
                        Text(publicKey)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                    }
                    Button(String(localized: "Regenerate key")) {
                        Task {
                            _ = await ChatEncryptionService.shared.generateKey(for: chatId)
                        }
                    }
                }
            }
        }
        .navigationTitle(String(localized: "Encryption"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            enabled = ChatEncryptionService.shared.isEncryptionEnabled(for: chatId)
        }
    }
}

// MARK: - Komet Misc (equivalent of komet_misc_screen.dart)

struct KometMiscView: View {
    @State private var freshModeEnabled = false
    @State private var showDevOptions   = false

    var body: some View {
        Form {
            Section(String(localized: "Behaviour")) {
                Toggle(String(localized: "Fresh mode"), isOn: $freshModeEnabled)
                Toggle(String(localized: "Show developer options"), isOn: $showDevOptions)
            }
        }
        .navigationTitle(String(localized: "Komet Misc"))
        .navigationBarTitleDisplayMode(.inline)
    }
}
