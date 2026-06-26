import SwiftUI

struct ReplyPreviewView: View {
    let message: Message
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: KometSpacing.sm) {
            Rectangle()
                .fill(Color.kometAccent)
                .frame(width: 3)
                .clipShape(Capsule())

            VStack(alignment: .leading, spacing: 2) {
                Text(String(localized: "Reply"))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.kometAccent)
                Text(message.text)
                    .font(.kometCaption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 20))
            }
        }
        .padding(.horizontal, KometSpacing.lg)
        .padding(.vertical, KometSpacing.sm)
        .background(Color(uiColor: .secondarySystemBackground))
    }
}
