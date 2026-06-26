import SwiftUI

// Type-safe navigation routes — replaces Navigator.push() from Flutter.
// Every screen in the app is reachable via a NavigationDestination case.

enum NavigationDestination: Hashable {
    // Chats
    case chat(chatId: Int)
    case newChat
    case channelsList
    case searchChats

    // Contacts
    case contactSearch(mode: ContactSearchMode)
    case editContact(userId: Int)
    case contactSelection(onSelect: ContactSelectionCallback)
    case userProfile(userId: Int)

    // Groups
    case groupSettings(chatId: Int)
    case joinGroup

    // Media
    case chatMediaGallery(chatId: Int)
    case downloads
    case musicLibrary
    case fullScreenVideo(url: URL)

    // Settings
    case settings
    case appearanceSettings
    case notificationSettings
    case privacySecurity
    case privacySettings
    case securitySettings
    case authSettings
    case sessions
    case exportSession
    case networkSettings
    case proxySettings
    case qrLogin
    case qrScanner(onScan: QRScanCallback)
    case reconnectionSettings
    case sessionSpoofing
    case plugins
    case pluginSection(pluginId: String)
    case storage
    case bypass
    case socketLog
    case about
    case cacheManagement
    case chatEncryptionSettings(chatId: Int)
    case manageAccount
    case debug
    case customRequest

    // Auth (not pushed via NavigationStack normally, but available for deep link)
    case otp(token: String, phone: String)
    case registration(trackId: String)
    case passwordAuth
    case tokenAuth

    // Workaround for non-Hashable closures — use opaque IDs
    static func == (lhs: NavigationDestination, rhs: NavigationDestination) -> Bool {
        switch (lhs, rhs) {
        case (.chat(let a), .chat(let b)): return a == b
        case (.settings, .settings): return true
        case (.appearanceSettings, .appearanceSettings): return true
        default: return false
        }
    }

    func hash(into hasher: inout Hasher) {
        switch self {
        case .chat(let id):            hasher.combine("chat"); hasher.combine(id)
        case .newChat:                 hasher.combine("newChat")
        case .settings:                hasher.combine("settings")
        case .appearanceSettings:      hasher.combine("appearanceSettings")
        case .chatMediaGallery(let id): hasher.combine("media"); hasher.combine(id)
        case .userProfile(let id):     hasher.combine("profile"); hasher.combine(id)
        case .groupSettings(let id):   hasher.combine("groupSettings"); hasher.combine(id)
        default:                       hasher.combine(String(describing: self))
        }
    }
}

// Closure wrappers — these can't be made Hashable; use callbacks sparingly.
typealias ContactSelectionCallback = (Contact) -> Void
typealias QRScanCallback           = (String) -> Void

enum ContactSearchMode: Hashable {
    case newChat
    case search
    case addToGroup(chatId: Int)
}
