import SwiftUI

struct ReconnectionOverlayView: View {
    let state: KometConnectionState
    let onRetry: () -> Void

    var body: some View {
        if case .disconnected = state {
            ZStack {
                Color.black.opacity(0.4).ignoresSafeArea()
                VStack(spacing: KometSpacing.lg) {
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 48))
                        .foregroundStyle(.white)
                    Text(String(localized: "No connection"))
                        .font(.kometTitle)
                        .foregroundStyle(.white)
                    KometButton(String(localized: "Retry"), style: .secondary, action: onRetry)
                        .frame(maxWidth: 200)
                }
                .padding(KometSpacing.xl)
                .kometGlass()
            }
            .transition(.opacity)
        }
    }
}
