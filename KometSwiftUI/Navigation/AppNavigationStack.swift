import SwiftUI

// Maps NavigationDestination → the correct View.
// Used as the navigationDestination(for:) resolver inside NavigationStack.

struct AppNavigationStack {
    @ViewBuilder
    static func view(for destination: NavigationDestination) -> some View {
        switch destination {
        case .chat(let id):
            ChatView(chatId: id)
        case .newChat:
            ContactSearchView(mode: .newChat)
        case .channelsList:
            ChannelsListView()
        case .searchChats:
            ContactSearchView(mode: .search)
        case .contactSearch(let mode):
            ContactSearchView(mode: mode)
        case .editContact(let userId):
            EditContactView(userId: userId)
        case .contactSelection:
            ContactSelectionView()
        case .userProfile(let userId):
            UserProfileView(userId: userId)
        case .groupSettings(let chatId):
            GroupSettingsView(chatId: chatId)
        case .joinGroup:
            JoinGroupView()
        case .chatMediaGallery(let chatId):
            ChatMediaGalleryView(chatId: chatId)
        case .downloads:
            DownloadsView()
        case .musicLibrary:
            MusicLibraryView()
        case .fullScreenVideo(let url):
            FullScreenVideoView(url: url)
        case .settings:
            SettingsView()
        case .appearanceSettings:
            AppearanceSettingsView()
        case .notificationSettings:
            NotificationSettingsView()
        case .privacySecurity:
            PrivacySecurityView()
        case .privacySettings:
            PrivacySettingsView()
        case .securitySettings:
            SecuritySettingsView()
        case .authSettings:
            AuthSettingsView()
        case .sessions:
            SessionsView()
        case .exportSession:
            ExportSessionView()
        case .networkSettings:
            NetworkSettingsView()
        case .proxySettings:
            ProxySettingsView()
        case .qrLogin:
            QRLoginView()
        case .qrScanner:
            QRScannerView(onScan: { _ in })
        case .reconnectionSettings:
            ReconnectionSettingsView()
        case .sessionSpoofing:
            SessionSpoofingView()
        case .plugins:
            PluginsView()
        case .pluginSection(let id):
            PluginSectionView(pluginId: id)
        case .storage:
            StorageView()
        case .bypass:
            BypassView()
        case .socketLog:
            SocketLogView()
        case .about:
            AboutView()
        case .cacheManagement:
            CacheManagementView()
        case .chatEncryptionSettings(let chatId):
            ChatEncryptionSettingsView(chatId: chatId)
        case .manageAccount:
            ManageAccountView()
        case .debug:
            DebugView()
        case .customRequest:
            CustomRequestView()
        case .otp(let token, let phone):
            OTPView(token: token, phone: phone)
        case .registration(let trackId):
            RegistrationView(trackId: trackId)
        case .passwordAuth:
            PasswordAuthView()
        case .tokenAuth:
            TokenAuthView()
        }
    }
}
