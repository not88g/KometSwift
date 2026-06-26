import SwiftUI

struct DebugView: View {
    @State private var showCustomRequest = false

    var body: some View {
        Form {
            Section(String(localized: "Connection")) {
                HStack {
                    Text(String(localized: "User ID"))
                    Spacer()
                    Text("\(AccountManager.shared.currentUserId)").foregroundStyle(.secondary)
                }
                Button(String(localized: "Disconnect")) {
                    Task { await ConnectionManager.shared.disconnect() }
                }
                Button(String(localized: "Reconnect")) {
                    Task { await ConnectionManager.shared.connect() }
                }
            }

            Section(String(localized: "Cache")) {
                Button(String(localized: "Print message cache count")) {}
                Button(role: .destructive) {
                    Task { await ChatCacheService.shared.clearAll() }
                } label: {
                    Text(String(localized: "Clear all caches"))
                }
            }

            Section(String(localized: "Custom Request")) {
                NavigationLink(value: NavigationDestination.customRequest) {
                    Text(String(localized: "Custom API request"))
                }
            }
        }
        .navigationTitle(String(localized: "Debug"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: NavigationDestination.self) {
            AppNavigationStack.view(for: $0)
        }
    }
}

struct CustomRequestView: View {
    @State private var opcodeStr = ""
    @State private var payloadStr = "{}"
    @State private var responseStr = ""
    @State private var isSending = false

    var body: some View {
        Form {
            Section(String(localized: "Request")) {
                TextField(String(localized: "Opcode (number)"), text: $opcodeStr)
                    .keyboardType(.numberPad)
                TextEditor(text: $payloadStr)
                    .frame(height: 120)
                    .font(.system(.caption, design: .monospaced))
            }

            Section {
                Button(String(localized: "Send")) {
                    Task { await send() }
                }
                .disabled(isSending || opcodeStr.isEmpty)
            }

            if !responseStr.isEmpty {
                Section(String(localized: "Response")) {
                    Text(responseStr)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                }
            }
        }
        .navigationTitle(String(localized: "Custom Request"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func send() async {
        guard let opcode = UInt16(opcodeStr),
              let data = payloadStr.data(using: .utf8),
              let payload = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
        else { return }

        isSending = true
        do {
            let response = try await APIService.shared.request(opcode: opcode, payload: payload)
            responseStr = (try? JSONSerialization.data(withJSONObject: response, options: .prettyPrinted))
                .flatMap { String(data: $0, encoding: .utf8) } ?? "\(response)"
        } catch {
            responseStr = error.localizedDescription
        }
        isSending = false
    }
}
