import SwiftUI

struct MessageBubbleView: View {
    let message: Message
    let isOutgoing: Bool
    let senderName: String?

    @Environment(\.kometUseLiquidGlass) private var useLiquidGlass

    var body: some View {
        HStack(alignment: .bottom, spacing: KometSpacing.sm) {
            if isOutgoing { Spacer(minLength: 60) }

            VStack(alignment: isOutgoing ? .trailing : .leading, spacing: 2) {
                // Group sender name
                if let name = senderName {
                    Text(name)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.kometAccent)
                        .padding(.horizontal, KometSpacing.bubblePadH)
                }

                // Reply/forward banner
                if message.isReply || message.isForwarded {
                    replyBanner
                }

                // Attachments
                if !message.attaches.isEmpty {
                    AttachmentPreviewView(attaches: message.attaches, isOutgoing: isOutgoing)
                }

                // Text body
                if !message.text.isEmpty || message.isDeleted {
                    bubbleBody
                }
            }
            .frame(
                maxWidth: UIScreen.main.bounds.width * 0.72,
                alignment: isOutgoing ? .trailing : .leading
            )

            if !isOutgoing { Spacer(minLength: 60) }
        }
        .padding(.horizontal, KometSpacing.md)
        .padding(.vertical, 1)
    }

    // MARK: - Bubble body

    private var bubbleBody: some View {
        VStack(alignment: .trailing, spacing: 3) {
            if message.isDeleted {
                Text(String(localized: "Message deleted"))
                    .italic()
                    .font(.kometBubble)
                    .foregroundStyle(.secondary)
            } else {
                Text(message.text)
                    .font(.kometBubble)
                    .foregroundStyle(isOutgoing ? .white : .primary)
                    .textSelection(.enabled)
            }

            // Timestamp + read status
            HStack(spacing: 3) {
                if message.isEdited {
                    Text(String(localized: "edited"))
                        .font(.system(size: 10))
                        .foregroundStyle(isOutgoing ? .white.opacity(0.7) : .secondary)
                }
                Text(message.formattedTime)
                    .font(.kometTimestamp)
                    .foregroundStyle(isOutgoing ? .white.opacity(0.7) : .secondary)
                if isOutgoing {
                    readStatusIcon
                }
            }
        }
        .padding(.horizontal, KometSpacing.bubblePadH)
        .padding(.vertical, KometSpacing.bubblePadV)
        .modifier(BubbleGlassModifier(isOutgoing: isOutgoing))
    }

    // MARK: - Read status

    private var readStatusIcon: some View {
        Group {
            if message.status == "READ" {
                Image(systemName: "checkmark.circle.fill")
            } else if message.status == "DELIVERED" {
                Image(systemName: "checkmark.circle")
            } else if message.status == "FAILED" {
                Image(systemName: "exclamationmark.circle")
                    .foregroundStyle(.red)
            } else {
                Image(systemName: "clock")
            }
        }
        .font(.system(size: 11))
        .foregroundStyle(.white.opacity(0.75))
    }

    // MARK: - Reply banner

    private var replyBanner: some View {
        HStack(spacing: 6) {
            Rectangle()
                .fill(Color.kometAccent)
                .frame(width: 3)
                .clipShape(Capsule())

            VStack(alignment: .leading, spacing: 1) {
                if message.isForwarded {
                    Text(String(localized: "Forwarded"))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.kometAccent)
                }
                let preview = message.link?["text"]?.value as? String ?? ""
                Text(preview)
                    .font(.kometCaption)
                    .lineLimit(2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, KometSpacing.bubblePadH)
        .padding(.vertical, 4)
    }
}
