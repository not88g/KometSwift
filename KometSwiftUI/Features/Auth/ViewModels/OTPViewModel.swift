import Foundation
import Observation
import Combine

@Observable
final class OTPViewModel {
    let token: String
    let phone: String

    var code = ""
    var isLoading = false
    var errorMessage: String?
    var navigateTo: NavigationDestination?

    private var cancellables = Set<AnyCancellable>()

    init(token: String, phone: String) {
        self.token = token
        self.phone = phone
        subscribeToSessionEvents()
    }

    var canSubmit: Bool { code.count == 4 && !isLoading }

    func submit() async {
        guard canSubmit else { return }
        isLoading = true
        errorMessage = nil
        do {
            try await APIService.shared.verifyCode(token: token, code: code)
            // Response handled in subscribeToSessionEvents()
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    private func subscribeToSessionEvents() {
        APIService.shared.sessionEventPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case .online:
                    self.isLoading = false
                    // Navigate to registration if new user, else authenticated
                    self.navigateTo = nil  // AppState handles the auth gate
                case .invalidToken:
                    self.isLoading = false
                    self.errorMessage = String(localized: "Invalid code. Try again.")
                default: break
                }
            }
            .store(in: &cancellables)
    }

    // Called when server demands a password for this account
    func handlePasswordRequired(trackId: String, hint: String?) {
        isLoading = false
        navigateTo = .passwordAuth
    }
}
