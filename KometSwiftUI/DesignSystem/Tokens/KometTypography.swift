import SwiftUI

extension Font {
    static var kometBody: Font      { .system(.body) }
    static var kometCaption: Font   { .system(.caption) }
    static var kometCaption2: Font  { .system(.caption2) }
    static var kometHeadline: Font  { .system(.headline) }
    static var kometSubheadline: Font { .system(.subheadline) }
    static var kometTitle: Font     { .system(.title3, weight: .semibold) }
    static var kometTimestamp: Font { .system(size: 11, weight: .regular, design: .monospaced) }
    static var kometBubble: Font    { .system(.callout) }
    static var kometLarge: Font     { .system(.title, weight: .bold) }
}
