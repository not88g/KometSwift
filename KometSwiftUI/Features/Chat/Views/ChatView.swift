import SwiftUI

struct ChatView: View {
    let chatId: Int
    @State private var viewModel: ChatViewModel
    @State private var showAttachmentMenu = false
    @Environment(AppState.self) private var appState
    @Environment(\.kometUseLiquidGlass) private var useLiquidGlass

    init(chatId: Int) {
        self.chatId = chatId
        self._viewModel = State(initialValue: ChatViewModel(chatId: chatId))
    }

    var body: some View {
        VStack(spacing: 0) {
            ConnectionStatusBannerView(state: viewModel.connectionState)
                .animation(.spring(duration: 0.3), value: viewModel.connectionState)

            // Pinned message
            if let pinned = viewModel.chat?.pinnedMessage {
                PinnedMessageView(message: pinned) {
                    viewModel.scrollToId = pinned.id
                }
            }

            // Message list
            messageList

            // Typing indicator
            if !viewModel.typingUserIds.isEmpty {
                HStack {
                    TypingDotsView()
                        .padding(.horizontal, KometSpacing.lg)
                        .padding(.vertical, KometSpacing.sm)
                    Spacer()
                }
            }

            // Input bar
            MessageInputView(viewModel: viewModel)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(viewModel.chat?.displayTitle ?? "")
        .toolbar { chatToolbar }
        .task { await viewModel.load() }
        .overlay(alignment: .center) {
            if viewModel.isLoading && viewModel.messages.isEmpty {
                ProgressView()
            }
        }
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 2) {
                    if viewModel.isLoadingMore {
                        ProgressView().padding()
                    }

                    ForEach(viewModel.messages) { message in
                        MessageBubbleView(
                            message: message,
                            isOutgoing: message.senderId == appState.currentUserId,
                            senderName: groupSenderName(message)
                        )
                        .id(message.id)
                        .onAppear {
                            Task { await viewModel.loadMoreIfNeeded(currentMessage: message) }
                        }
                        .contextMenu {
                            messageContextMenu(message)
                        }
                    }
                }
                .padding(.vertical, KometSpacing.sm)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: viewModel.scrollToId) { _, id in
                if let id {
                    withAnimation { proxy.scrollTo(id, anchor: .bottom) }
                }
            }
            .onAppear {
                if let last = viewModel.messages.last {
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            }
        }
    }

    @ViewBuilder
    private func messageContextMenu(_ message: Message) -> some View {
        Button {
            viewModel.replyToMessage = message
        } label: {
            Label(String(localized: "Reply"), systemImage: "arrowshape.turn.up.left")
        }

        if message.senderId == appState.currentUserId && message.canEdit(currentUserId: appState.currentUserId) {
            Button {
                // Edit handled via sheet in production
            } label: {
                Label(String(localized: "Edit"), systemImage: "pencil")
            }
        }

        Button(role: .destructive) {
            Task { await viewModel.deleteMessage(message) }
        } label: {
            Label(String(localized: "Delete"), systemImage: "trash")
        }
    }

    private func groupSenderName(_ message: Message) -> String? {
        guard viewModel.chat?.isGroup == true,
              message.senderId != appState.currentUserId
        else { return nil }
        // Contact name lookup — simplified; full implementation fetches from cache
        return "User \(message.senderId)"
    }

    @ToolbarContentBuilder
    private var chatToolbar: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            if let chat = viewModel.chat {
                Button {
                    // Push group settings or user profile
                } label: {
                    VStack(spacing: 1) {
                        Text(chat.displayTitle).font(.kometHeadline)
                        Text(chat.isGroup
                             ? String(localized: "\(chat.participantIds.count) members")
                             : String(localized: "Online"))
                            .font(.kometCaption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            AvatarView(
                baseUrl: viewModel.chat?.baseIconUrl,
                displayName: viewModel.chat?.displayTitle ?? "",
                size: KometSpacing.avatarSizeSm
            )
        }
    }
}
