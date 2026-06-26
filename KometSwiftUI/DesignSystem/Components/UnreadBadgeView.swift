import SwiftUI

struct UnreadBadgeView: View {
    let count: Int
    var muted: Bool = false

    var body: some View {
        if count > 0 {
            Text(count > 999 ? "999+" : "\(count)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(muted ? Color.gray : Color.kometAccent, in: Capsule())
                .fixedSize()
        }
    }
}
