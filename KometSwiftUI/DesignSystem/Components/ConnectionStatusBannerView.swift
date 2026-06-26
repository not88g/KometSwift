import SwiftUI

struct ConnectionStatusBannerView: View {
    let state: KometConnectionState

    var body: some View {
        if shouldShow {
            HStack(spacing: KometSpacing.sm) {
                if isSpinning {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.75)
                        .tint(.white)
                }
                Text(label)
                    .font(.kometCaption)
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, KometSpacing.sm)
            .background(bannerColor)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    private var shouldShow: Bool {
        if case .connected = state { return false }
        if case .idle      = state { return false }
        return true
    }

    private var isSpinning: Bool {
        switch state {
        case .connecting, .reconnecting: return true
        default: return false
        }
    }

    private var label: String {
        switch state {
        case .connecting:   return String(localized: "Connecting…")
        case .reconnecting: return String(localized: "Reconnecting…")
        case .disconnected: return String(localized: "No connection")
        case .error(let m): return m
        default:            return ""
        }
    }

    private var bannerColor: Color {
        switch state {
        case .disconnected, .error: return Color.kometDestructive
        default: return .orange
        }
    }
}
