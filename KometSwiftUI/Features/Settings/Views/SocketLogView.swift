import SwiftUI
import Combine

struct SocketLogView: View {
    @State private var logs: [String] = []
    @State private var cancellable: AnyCancellable?
    @State private var autoScroll = true

    var body: some View {
        VStack(spacing: 0) {
            toolbar

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(logs.indices, id: \.self) { i in
                            Text(logs[i])
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(logColor(logs[i]))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .id(i)
                        }
                    }
                    .padding(KometSpacing.sm)
                }
                .onChange(of: logs.count) { _, _ in
                    if autoScroll, let last = logs.indices.last {
                        proxy.scrollTo(last, anchor: .bottom)
                    }
                }
            }
        }
        .navigationTitle(String(localized: "Socket Log"))
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.black)
        .onAppear { startListening() }
        .onDisappear { cancellable?.cancel() }
    }

    private var toolbar: some View {
        HStack {
            Toggle(String(localized: "Auto-scroll"), isOn: $autoScroll)
                .labelsHidden()
            Text(String(localized: "Auto-scroll"))
                .font(.kometCaption)
            Spacer()
            Button(String(localized: "Clear")) { logs.removeAll() }
                .font(.kometCaption)
                .foregroundStyle(.red)
        }
        .padding(.horizontal, KometSpacing.md)
        .padding(.vertical, KometSpacing.sm)
        .background(Color(uiColor: .secondarySystemBackground))
    }

    private func startListening() {
        cancellable = APIService.shared.connectionLogPublisher
            .receive(on: DispatchQueue.main)
            .sink { entry in
                logs.append("[\(Date().formatted(date: .omitted, time: .standard))] \(entry)")
                if logs.count > 500 { logs.removeFirst() }
            }
    }

    private func logColor(_ log: String) -> Color {
        if log.contains("✅") || log.contains("connected") { return .green }
        if log.contains("❌") || log.contains("error") || log.contains("Error") { return .red }
        if log.contains("⚠️") { return .orange }
        return .green.opacity(0.8)
    }
}
