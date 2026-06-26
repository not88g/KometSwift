import SwiftUI

// MARK: - Environment key

private struct LiquidGlassKey: EnvironmentKey {
    static let defaultValue = true
}

extension EnvironmentValues {
    var kometUseLiquidGlass: Bool {
        get { self[LiquidGlassKey.self] }
        set { self[LiquidGlassKey.self] = newValue }
    }
}

// MARK: - Glass background modifier

struct KometGlassBackground<S: Shape>: ViewModifier {
    @Environment(\.kometUseLiquidGlass) private var useLiquidGlass

    let shape: S
    let fallbackMaterial: Material

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *), useLiquidGlass {
            content.glassEffect(in: shape)
        } else {
            content.background(fallbackMaterial, in: shape)
        }
    }
}

// MARK: - Convenience View extensions

extension View {
    func kometGlass(
        shape: some Shape = RoundedRectangle(cornerRadius: KometSpacing.cornerRadius, style: .continuous),
        fallback: Material = .regularMaterial
    ) -> some View {
        modifier(KometGlassBackground(shape: shape, fallbackMaterial: fallback))
    }

    func kometGlassCapsule(fallback: Material = .ultraThinMaterial) -> some View {
        modifier(KometGlassBackground(shape: Capsule(), fallbackMaterial: fallback))
    }

    func kometGlassCircle(fallback: Material = .regularMaterial) -> some View {
        modifier(KometGlassBackground(shape: Circle(), fallbackMaterial: fallback))
    }
}

// MARK: - Bubble glass

struct BubbleGlassModifier: ViewModifier {
    @Environment(\.kometUseLiquidGlass) private var useLiquidGlass
    let isOutgoing: Bool

    private var shape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius:    isOutgoing ? KometSpacing.bubbleRadius : KometSpacing.smallRadius,
            bottomLeadingRadius: KometSpacing.bubbleRadius,
            bottomTrailingRadius: isOutgoing ? KometSpacing.smallRadius : KometSpacing.bubbleRadius,
            topTrailingRadius:   isOutgoing ? KometSpacing.bubbleRadius : KometSpacing.bubbleRadius,
            style: .continuous
        )
    }

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *), useLiquidGlass, !isOutgoing {
            content.glassEffect(in: shape)
        } else {
            content.background(isOutgoing ? Color.kometBubbleOut : Color.kometBubbleIn, in: shape)
        }
    }
}
