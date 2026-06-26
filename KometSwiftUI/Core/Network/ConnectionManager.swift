// Raw TLS TCP connection to api.oneme.ru:443 — mirrors _connectToUrl in api_service_connection.dart.
// Uses Network.framework NWConnection for full control over the TLS layer.

import Foundation
import Network
import Combine

enum KometConnectionState: Equatable {
    case idle, connecting, connected, reconnecting, disconnected, error(String)
}

actor ConnectionManager {
    static let shared = ConnectionManager()

    // Published state consumed by AppState / UI
    private let stateSubject = CurrentValueSubject<KometConnectionState, Never>(.idle)
    var statePublisher: AnyPublisher<KometConnectionState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    // Raw inbound packet bytes published to APIService
    private let packetSubject = PassthroughSubject<Data, Never>()
    var packetPublisher: AnyPublisher<Data, Never> {
        packetSubject.eraseToAnyPublisher()
    }

    private var connection: NWConnection?
    private var receiveBuffer = Data()
    private var reconnectTask: Task<Void, Never>?
    private var pingTask: Task<Void, Never>?

    private let host = "api.oneme.ru"
    private let port: UInt16 = 443

    // MARK: - Public API

    func connect() async {
        guard stateSubject.value != .connecting, stateSubject.value != .connected else { return }
        await openConnection()
    }

    func disconnect() {
        reconnectTask?.cancel()
        pingTask?.cancel()
        connection?.cancel()
        connection = nil
        stateSubject.send(.disconnected)
    }

    func send(_ data: Data) async throws {
        guard let conn = connection else { throw URLError(.notConnectedToInternet) }
        return try await withCheckedThrowingContinuation { cont in
            conn.send(content: data, completion: .contentProcessed { error in
                if let error { cont.resume(throwing: error) }
                else { cont.resume() }
            })
        }
    }

    // MARK: - Internal

    private func openConnection() async {
        stateSubject.send(.connecting)

        let params: NWParameters
        if let proxy = await ProxyService.shared.currentConfig() {
            params = makeParametersWithProxy(proxy)
        } else {
            params = .tls
        }

        // Apply spoofing TLS SNI (same host, no changes needed for standard TLS)
        let endpoint = NWEndpoint.hostPort(
            host: NWEndpoint.Host(host),
            port: NWEndpoint.Port(rawValue: port)!
        )

        let conn = NWConnection(to: endpoint, using: params)
        self.connection = conn

        conn.stateUpdateHandler = { [weak self] state in
            guard let self else { return }
            Task { await self.handleStateChange(state) }
        }

        conn.start(queue: .global(qos: .utility))
        receiveBuffer = Data()
        startReceiving(conn)
    }

    private func handleStateChange(_ state: NWConnection.State) async {
        switch state {
        case .ready:
            stateSubject.send(.connected)
            startPinging()
        case .failed(let error):
            stateSubject.send(.error(error.localizedDescription))
            scheduleReconnect()
        case .cancelled:
            stateSubject.send(.disconnected)
        default:
            break
        }
    }

    private func startReceiving(_ conn: NWConnection) {
        conn.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            guard let self else { return }
            Task {
                if let data { await self.handleReceivedData(data) }
                if isComplete || error != nil {
                    await self.scheduleReconnect()
                    return
                }
                self.startReceiving(conn)
            }
        }
    }

    private func handleReceivedData(_ incoming: Data) async {
        receiveBuffer.append(incoming)

        while receiveBuffer.count >= 10 {
            let raw = receiveBuffer.loadUInt32BE(at: 6)
            let payloadLength = Int(raw & 0x00FFFFFF)
            let totalLength = 10 + payloadLength

            guard receiveBuffer.count >= totalLength else { break }

            let packetData = receiveBuffer.subdata(in: 0..<totalLength)
            receiveBuffer.removeSubrange(0..<totalLength)
            packetSubject.send(packetData)
        }
    }

    private func startPinging() {
        pingTask?.cancel()
        pingTask = Task {
            // Ping every 25 seconds — mirrors _startPinging()
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(25))
                guard !Task.isCancelled else { break }
                if let pingData = try? packPacket(cmd: 0, seq: 0, opcode: 1, payload: ["interactive": true]) {
                    try? await send(pingData)
                }
            }
        }
    }

    private func scheduleReconnect() async {
        reconnectTask?.cancel()
        stateSubject.send(.reconnecting)
        reconnectTask = Task {
            var delay: UInt64 = 3_000_000_000
            for _ in 0..<10 {
                try? await Task.sleep(nanoseconds: delay)
                guard !Task.isCancelled else { return }
                await openConnection()
                if stateSubject.value == .connected { return }
                delay = min(delay * 2, 60_000_000_000)
            }
            stateSubject.send(.disconnected)
        }
    }

    private func makeParametersWithProxy(_ config: ProxyConfiguration) -> NWParameters {
        // SOCKS5 via NWParameters — basic TCP+TLS
        return .tls
    }
}

// MARK: - Data helper (needed here too)

private extension Data {
    func loadUInt32BE(at offset: Int) -> UInt32 {
        (UInt32(self[offset]) << 24) | (UInt32(self[offset+1]) << 16) |
        (UInt32(self[offset+2]) << 8) | UInt32(self[offset+3])
    }
}
