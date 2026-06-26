import SwiftUI

// All color tokens resolve from Assets.xcassets (light/dark variants defined there).
// The accent and bubble colors should match Komet's existing palette from app_colors.dart.

extension Color {
    static var kometAccent: Color      { Color("KometAccent",     bundle: nil) }
    static var kometBackground: Color  { Color("KometBackground", bundle: nil) }
    static var kometSurface: Color     { Color("KometSurface",    bundle: nil) }
    static var kometOnSurface: Color   { Color("KometOnSurface",  bundle: nil) }
    static var kometDestructive: Color { Color("KometDestructive",bundle: nil) }
    static var kometBubbleOut: Color   { Color("BubbleOutgoing",  bundle: nil) }
    static var kometBubbleIn: Color    { Color("BubbleIncoming",  bundle: nil) }
    static var kometSecondary: Color   { Color("KometSecondary",  bundle: nil) }
}

// MARK: - Fallback inline values (used if asset catalog colors are missing)

extension Color {
    static var kometAccentFallback: Color      { Color(red: 0.27, green: 0.53, blue: 0.98) }
    static var kometBubbleOutFallback: Color   { Color(red: 0.27, green: 0.53, blue: 0.98) }
    static var kometBubbleInFallback: Color    { Color(uiColor: .secondarySystemGroupedBackground) }
    static var kometDestructiveFallback: Color { Color.red }
}
