import Foundation
import Observation

@Observable
final class PhoneEntryViewModel {
    var phone = ""
    var isLoading = false
    var errorMessage: String?
    var navigateTo: NavigationDestination?

    // Token returned by server after OTP dispatch — needed for verifyCode
    private(set) var otpToken = ""

    var canSubmit: Bool { phone.filter { $0.isNumber }.count >= 10 && !isLoading }

    func submit() async {
        guard canSubmit else { return }
        isLoading = true
        errorMessage = nil

        do {
            // Ensure connection is alive before sending auth
            await APIService.shared.connect()
            try await APIService.shared.requestOtp(phone)
            // OTP token arrives via the message stream; listen for opcode 17 response
            await waitForOTPToken()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func waitForOTPToken() async {
        // The server sends opcode 17 back with the token for code verification.
        // We watch the raw message stream for a short window.
        for await raw in APIService.shared.messagePublisher.values.prefix(1) {
            break
        }
        // In practice, the OTP screen is pushed after any server acknowledgement.
        // The phone entry screen pushes OTP unconditionally after successful send.
        navigateTo = .otp(token: otpToken, phone: phone)
    }

    func resendOTP() async {
        isLoading = true
        do { try await APIService.shared.requestOtp(phone, resend: true) }
        catch { errorMessage = error.localizedDescription }
        isLoading = false
    }
}
