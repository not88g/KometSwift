// Central API service — singleton, mirrors ApiService in api_service.dart.
// All message sending/receiving is through the raw TLS socket via ConnectionManager.
// Opcodes mirror the Flutter implementation exactly.

import Foundation
import Combine

final class APIService {
    static let shared = APIService()
    private init() {
        subscribeToPackets()
    }

    // MARK: - State

    private(set) var authToken: String?
    private(set) var currentUserId: Int = 0

    private var seq: UInt8 = 0
    private var sessionId: Int = Int(Date().timeIntervalSince1970 * 1000)
    private var actionId: Int = 1
    private var handshakeSent = false
    private var isSessionOnline = false
    private var isSessionReady = false

    // Pending request completions keyed by seq
    private var pending: [UInt8: CheckedContinuation<[String: Any], Error>] = [:]
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Publishers (consumed by ViewModels)

    let messagePublisher       = PassthroughSubject<Message, Never>()
    let contactUpdatePublisher = PassthroughSubject<Contact, Never>()
    let chatsPublisher         = PassthroughSubject<[Chat], Never>()
    let connectionPublisher    = PassthroughSubject<String, Never>()
    let sessionEventPublisher  = PassthroughSubject<SessionEvent, Never>()
    let connectionLogPublisher = PassthroughSubject<String, Never>()

    enum SessionEvent {
        case terminated, invalidToken, online, offline
    }

    // MARK: - Auth

    func setAuthToken(_ token: String) {
        authToken = token
    }

    func clearAuthToken() {
        authToken = nil
        handshakeSent = false
        isSessionOnline = false
        isSessionReady = false
    }

    func hasToken() async -> Bool {
        authToken != nil || (await TokenStore.shared.hasToken())
    }

    // MARK: - Connection lifecycle

    func connect() async {
        if authToken == nil {
            authToken = await TokenStore.shared.loadToken()
            currentUserId = await TokenStore.shared.loadUserId() ?? 0
        }
        await ConnectionManager.shared.connect()
    }

    // MARK: - Packet subscription

    private func subscribeToPackets() {
        ConnectionManager.shared.packetPublisher
            .receive(on: DispatchQueue.global(qos: .utility))
            .sink { [weak self] data in
                guard let self else { return }
                self.handleRawPacket(data)
            }
            .store(in: &cancellables)

        ConnectionManager.shared.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                switch state {
                case .connected:
                    Task { await self?.onConnected() }
                case .disconnected, .error:
                    self?.isSessionOnline = false
                    self?.isSessionReady = false
                default: break
                }
            }
            .store(in: &cancellables)
    }

    private func onConnected() async {
        handshakeSent = false
        await sendHandshake()
    }

    // MARK: - Handshake (opcode 6)

    private func sendHandshake() async {
        guard !handshakeSent else { return }
        handshakeSent = true

        let spoofing = await SpoofingService.shared.buildUserAgentPayload()
        let defaults = UserDefaults.standard

        var mtInstanceId = defaults.string(forKey: "session_mt_instanceid") ?? ""
        var clientSessionId = defaults.integer(forKey: "session_client_session_id")

        if mtInstanceId.isEmpty || clientSessionId == 0 {
            mtInstanceId = UUID().uuidString
            clientSessionId = Int.random(in: 1...100)
            defaults.set(mtInstanceId, forKey: "session_mt_instanceid")
            defaults.set(clientSessionId, forKey: "session_client_session_id")
        }

        let deviceId = defaults.string(forKey: "spoof_deviceid") ?? UUID().uuidString

        let payload: [String: Any] = [
            "mt_instanceid":   mtInstanceId,
            "clientSessionId": clientSessionId,
            "deviceId":        deviceId,
            "userAgent":       spoofing,
        ]

        try? await sendMessage(opcode: 6, payload: payload)
        log("Handshake sent")
    }

    // MARK: - Incoming packet dispatch

    private func handleRawPacket(_ data: Data) {
        guard let packet = try? unpackPacket(data) else { return }
        log("← opcode=\(packet.opcode) cmd=\(packet.cmd)")

        switch packet.opcode {
        case 1: handlePong(packet)
        case 6: handleHandshakeResponse(packet)
        case 10: handleSessionOnline(packet)
        case 11: handleNewMessage(packet)
        case 12: handleMessageUpdate(packet)
        case 13: handleMessageDelete(packet)
        case 15: handleChatsUpdate(packet)
        case 17: handleAuthOtpResponse(packet)
        case 18: handleAuthVerifyResponse(packet)
        case 20: handleContactUpdate(packet)
        case 30: handleSessionTerminated(packet)
        case 31: handleInvalidToken(packet)
        default:
            // Route to pending request if seq matches
            if let cont = pending[packet.seq] {
                pending.removeValue(forKey: packet.seq)
                cont.resume(returning: packet.payload)
            }
        }
    }

    // MARK: - Session event handlers

    private func handleHandshakeResponse(_ packet: Packet) {
        // After handshake confirmed, authenticate if we have a token
        if let token = authToken, !token.isEmpty {
            Task { try? await sendMessage(opcode: 19, payload: ["token": token]) }
        }
    }

    private func handleSessionOnline(_ packet: Packet) {
        isSessionOnline = true
        isSessionReady = true
        currentUserId = packet.payload["userId"] as? Int ?? currentUserId
        sessionEventPublisher.send(.online)
        connectionPublisher.send("connected")
        log("Session online, userId=\(currentUserId)")
    }

    private func handleSessionTerminated(_ packet: Packet) {
        clearAuthToken()
        sessionEventPublisher.send(.terminated)
        connectionPublisher.send("disconnected")
    }

    private func handleInvalidToken(_ packet: Packet) {
        clearAuthToken()
        Task { await TokenStore.shared.clearToken() }
        sessionEventPublisher.send(.invalidToken)
    }

    private func handlePong(_ packet: Packet) { /* keep-alive */ }

    private func handleNewMessage(_ packet: Packet) {
        if let msgData = packet.payload["message"] as? [String: Any] {
            messagePublisher.send(Message(from: msgData))
        }
    }

    private func handleMessageUpdate(_ packet: Packet) {
        if let msgData = packet.payload["message"] as? [String: Any] {
            messagePublisher.send(Message(from: msgData))
        }
    }

    private func handleMessageDelete(_ packet: Packet) {
        if var msgData = packet.payload["message"] as? [String: Any] {
            msgData["isDeleted"] = true
            messagePublisher.send(Message(from: msgData))
        }
    }

    private func handleChatsUpdate(_ packet: Packet) {
        if let rawChats = packet.payload["chats"] as? [[String: Any]] {
            chatsPublisher.send(rawChats.map { Chat(from: $0) })
        }
    }

    private func handleContactUpdate(_ packet: Packet) {
        if let raw = packet.payload["contact"] as? [String: Any] {
            contactUpdatePublisher.send(Contact(from: raw))
        }
    }

    private func handleAuthOtpResponse(_ packet: Packet) {
        // Forwarded to PhoneEntryViewModel via sessionEventPublisher / specific handler
        pending[packet.seq]?.resume(returning: packet.payload)
        pending.removeValue(forKey: packet.seq)
    }

    private func handleAuthVerifyResponse(_ packet: Packet) {
        pending[packet.seq]?.resume(returning: packet.payload)
        pending.removeValue(forKey: packet.seq)
    }

    // MARK: - Send

    func sendMessage(opcode: UInt16, payload: [String: Any]) async throws {
        let s = nextSeq()
        let data = try packPacket(cmd: 0, seq: s, opcode: opcode, payload: payload)
        try await ConnectionManager.shared.send(data)
    }

    func request(opcode: UInt16, payload: [String: Any]) async throws -> [String: Any] {
        let s = nextSeq()
        return try await withCheckedThrowingContinuation { cont in
            pending[s] = cont
            Task {
                do {
                    let data = try packPacket(cmd: 0, seq: s, opcode: opcode, payload: payload)
                    try await ConnectionManager.shared.send(data)
                } catch {
                    self.pending.removeValue(forKey: s)
                    cont.resume(throwing: error)
                }
            }
        }
    }

    private func nextSeq() -> UInt8 {
        seq = seq &+ 1
        return seq
    }

    private func log(_ msg: String) {
        connectionLogPublisher.send(msg)
    }
}
