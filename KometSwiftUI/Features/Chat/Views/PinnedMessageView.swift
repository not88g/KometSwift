import SwiftUI

struct PinnedMessageView: View {
    let message: Message
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: KometSpacing.sm) {
                Rectangle()
                    .fill(Color.kometAccent)
                    .frame(width: 3)
                    .clipShape(Capsule())

                VStack(alignment: .leading, spacing: 2) {
                    Text(String(localized: "Pinned Message"))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.kometAccent)
                    Text(message.text)
                        .font(.kometCaption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, KometSpacing.lg)
            .padding(.vertical, KometSpacing.sm)
            .background(Color(uiColor: .secondarySystemBackground))
        }
        .buttonStyle(.plain)
    }
}
