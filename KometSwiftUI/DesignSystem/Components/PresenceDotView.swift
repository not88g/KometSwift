import SwiftUI

struct PresenceDotView: View {
    let isOnline: Bool
    var dotSize: CGFloat = 10

    var body: some View {
        Circle()
            .fill(isOnline ? Color.green : Color.gray.opacity(0.4))
            .frame(width: dotSize, height: dotSize)
            .overlay(
                Circle()
                    .stroke(Color(uiColor: .systemBackground), lineWidth: 1.5)
            )
    }
}
