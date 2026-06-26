// Auth-related API calls — mirrors api_service_auth.dart.
// Opcode reference:
//   17 = requestOtp / START_AUTH / RESEND
//   18 = verifyCode (CHECK_CODE)
//   19 = loginWithToken
//   115 = sendPassword
//   116 = setAccountPassword
//   96  = requestSessions
//   97  = terminateAllSessions

import Foundation

extension APIService {

    // MARK: - OTP

    func requestOtp(_ phone: String, resend: Bool = false) async throws {
        if !(await ConnectionManager.shared.statePublisher.values.first(where: { _ in true }) != nil) {
            await connect()
        }
        let payload: [String: Any] = [
            "phone": phone,
            "type":  resend ? "RESEND" : "START_AUTH",
        ]
        try await sendMessage(opcode: 17, payload: payload)
    }

    func verifyCode(token: String, code: String) async throws {
        let payload: [String: Any] = [
            "verifyCode":     code,
            "token":          token,
            "authTokenType":  "CHECK_CODE",
        ]
        try await sendMessage(opcode: 18, payload: payload)
    }

    // MARK: - Password

    func sendPassword(trackId: String, password: String) async throws {
        try await sendMessage(opcode: 115, payload: ["trackId": trackId, "password": password])
    }

    func setAccountPassword(password: String, hint: String) async throws {
        try await sendMessage(opcode: 116, payload: ["password": password, "hint": hint])
    }

    // MARK: - Token login

    func loginWithToken(_ token: String) async throws {
        self.authToken = token
        try await sendMessage(opcode: 19, payload: ["token": token])
    }

    // MARK: - Sessions

    func requestSessions() async throws {
        try await sendMessage(opcode: 96, payload: [:])
    }

    func terminateAllSessions() async throws {
        try await sendMessage(opcode: 97, payload: [:])
    }

    func terminateSession(sessionId: Int) async throws {
        try await sendMessage(opcode: 98, payload: ["sessionId": sessionId])
    }

    // MARK: - Registration

    func register(firstName: String, lastName: String, trackId: String) async throws {
        let payload: [String: Any] = [
            "firstName": firstName,
            "lastName":  lastName,
            "trackId":   trackId,
        ]
        try await sendMessage(opcode: 22, payload: payload)
    }

    // MARK: - QR Login

    func requestQRCode() async throws -> String {
        let response = try await request(opcode: 105, payload: [:])
        return response["qrCode"] as? String ?? ""
    }

    func authorizeQR(code: String) async throws {
        try await sendMessage(opcode: 106, payload: ["code": code])
    }

    // MARK: - Logout

    func logout() async {
        try? await sendMessage(opcode: 99, payload: [:])
        clearAuthToken()
        await TokenStore.shared.clearToken()
        await ChatCacheService.shared.clearAll()
    }
}
