import SwiftUI
import Observation
import Combine

@Observable
final class AppState {
    // MARK: - Auth gate
    var isAuthenticated = false
    var isBootstrapping = true

    // MARK: - Connection
    var connectionState: KometConnectionState = .idle

    // MARK: - Current user
    var currentUserId: Int = 0

    // MARK: - Appearance
    var useLiquidGlass: Bool = {
        if UserDefaults.standard.object(forKey: "komet.liquidGlassEnabled") == nil { return true }
        return UserDefaults.standard.bool(forKey: "komet.liquidGlassEnabled")
    }() {
        didSet { UserDefaults.standard.set(useLiquidGlass, forKey: "komet.liquidGlassEnabled") }
    }

    var colorScheme: ColorScheme? = {
        switch UserDefaults.standard.string(forKey: "komet.colorScheme") {
        case "light": return .light
        case "dark":  return .dark
        default:      return nil
        }
    }() {
        didSet {
            let v: String
            switch colorScheme {
            case .light: v = "light"
            case .dark:  v = "dark"
            default:     v = "system"
            }
            UserDefaults.standard.set(v, forKey: "komet.colorScheme")
        }
    }

    // MARK: - Cancellables
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Bootstrap

    func bootstrap() async {
        // Services must be initialised in this order (mirrors main.dart)
        await CacheService.shared.initialize()
        await AvatarCacheService.shared.initialize()
        await ChatCacheService.shared.initialize()
        await ContactLocalNamesService.shared.initialize()
        await MessageQueueService.shared.initialize()
        await AccountManager.shared.initialize()
        await PluginService.shared.initialize()
        await WhitelistService.shared.initialize()
        await NotificationService.shared.initialize()
        await SpoofingService.shared.generateIfNeeded()
        ConnectionLifecycleManager.shared.start()

        subscribeToConnectionState()
        subscribeToSessionEvents()

        let hasToken = await TokenStore.shared.hasToken()
        if hasToken {
            await WhitelistService.shared.validate()
            await APIService.shared.connect()
            currentUserId = await AccountManager.shared.currentUserId
            isAuthenticated = true
        }

        await MainActor.run { isBootstrapping = false }
    }

    // MARK: - Session event handling

    private func subscribeToSessionEvents() {
        APIService.shared.sessionEventPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                switch event {
                case .invalidToken, .terminated:
                    self?.isAuthenticated = false
                case .online:
                    Task { await MessageQueueService.shared.flushQueue() }
                case .offline:
                    break
                }
            }
            .store(in: &cancellables)
    }

    private func subscribeToConnectionState() {
        ConnectionManager.shared.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in self?.connectionState = state }
            .store(in: &cancellables)
    }

    func signIn(token: String, userId: Int, displayName: String) async {
        let account = Account(token: token, userId: userId, displayName: displayName)
        await AccountManager.shared.addOrUpdateAccount(account)
        await APIService.shared.loginWithToken(token)
        currentUserId = userId
        await MainActor.run { isAuthenticated = true }
    }

    func signOut() async {
        await APIService.shared.logout()
        await MainActor.run { isAuthenticated = false }
    }
}
