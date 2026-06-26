import SwiftUI

struct KometButton: View {
    enum Style { case primary, secondary, destructive, ghost }

    let label: String
    let style: Style
    let isLoading: Bool
    let action: () -> Void

    init(_ label: String, style: Style = .primary, isLoading: Bool = false, action: @escaping () -> Void) {
        self.label = label; self.style = style; self.isLoading = isLoading; self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: KometSpacing.sm) {
                if isLoading { ProgressView().tint(foregroundColor) }
                Text(label).font(.system(.body, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, KometSpacing.md)
            .padding(.horizontal, KometSpacing.xl)
            .background(backgroundColor, in: RoundedRectangle(cornerRadius: KometSpacing.cornerRadius, style: .continuous))
            .foregroundStyle(foregroundColor)
        }
        .disabled(isLoading)
        .buttonStyle(.plain)
    }

    private var backgroundColor: Color {
        switch style {
        case .primary:     return .kometAccent
        case .secondary:   return Color(uiColor: .secondarySystemFill)
        case .destructive: return .kometDestructive
        case .ghost:       return .clear
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary, .destructive: return .white
        case .secondary, .ghost:     return .primary
        }
    }
}
