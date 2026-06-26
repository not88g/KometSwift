import SwiftUI

struct ChatRowView: View {
    let chat: Chat
    @Environment(AppState.self) private var appState

    var body: some View {
        HStack(spacing: KometSpacing.md) {
            AvatarView(
                baseUrl: chat.baseIconUrl,
                displayName: chat.displayTitle,
                size: KometSpacing.avatarSizeLg
            )

            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .top) {
                    Text(chat.displayTitle)
                        .font(.kometHeadline)
                        .lineLimit(1)
                    Spacer()
                    Text(chat.lastMessage.formattedDate)
                        .font(.kometCaption)
                        .foregroundStyle(.secondary)
                }

                HStack(alignment: .bottom) {
                    lastMessageText
                        .font(.kometBody)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    Spacer(minLength: KometSpacing.sm)
                    UnreadBadgeView(
                        count: chat.newMessages,
                        muted: NotificationService.shared.isMuted(chatId: chat.id)
                    )
                }
            }
        }
        .padding(.vertical, KometSpacing.xs)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var lastMessageText: some View {
        if chat.lastMessage.isDeleted {
            Text(String(localized: "Message deleted")).italic()
        } else if !chat.lastMessage.attaches.isEmpty {
            Label(attachmentLabel, systemImage: attachmentIcon)
        } else if !chat.lastMessage.text.isEmpty {
            Text(chat.lastMessage.text)
        } else {
            Text(String(localized: "No messages yet"))
        }
    }

    private var attachmentLabel: String {
        let type = chat.lastMessage.attaches.first?["_type"]?.value as? String
            ?? chat.lastMessage.attaches.first?["type"]?.value as? String ?? ""
        switch type {
        case "IMAGE": return String(localized: "Photo")
        case "VIDEO": return String(localized: "Video")
        case "AUDIO": return String(localized: "Audio")
        case "FILE":  return String(localized: "File")
        default:      return String(localized: "Attachment")
        }
    }

    private var attachmentIcon: String {
        let type = chat.lastMessage.attaches.first?["_type"]?.value as? String
            ?? chat.lastMessage.attaches.first?["type"]?.value as? String ?? ""
        switch type {
        case "IMAGE": return "photo"
        case "VIDEO": return "video"
        case "AUDIO": return "music.note"
        case "FILE":  return "doc"
        default:      return "paperclip"
        }
    }
}
