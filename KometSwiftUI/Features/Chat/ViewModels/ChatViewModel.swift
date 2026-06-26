import Foundation
import Observation
import Combine

@Observable
final class ChatViewModel {
    let chatId: Int

    var messages: [Message] = []
    var chat: Chat?
    var isLoading = false
    var isLoadingMore = false
    var typingUserIds: Set<Int> = []
    var inputText = ""
    var replyToMessage: Message?
    var encryptionEnabled = false
    var selectedAttachments: [URL] = []
    var connectionState: KometConnectionState = .idle
    var scrollToId: String?

    private var cancellables = Set<AnyCancellable>()
    private var oldestMessageId: String?

    init(chatId: Int) {
        self.chatId = chatId
        self.encryptionEnabled = ChatEncryptionService.shared.isEncryptionEnabled(for: chatId)
    }

    // MARK: - Load

    func load() async {
        isLoading = true
        defer { isLoading = false }

        // Cache first
        messages = await ChatCacheService.shared.messages(for: chatId)

        do {
            let fetched = try await APIService.shared.fetchMessages(chatId: chatId)
            messages = fetched.sorted { $0.time < $1.time }
            oldestMessageId = fetched.min(by: { $0.time < $1.time })?.id
            await ChatCacheService.shared.store(messages: messages, for: chatId)
        } catch {}

        subscribeToUpdates()
        markLatestRead()
    }

    // MARK: - Pagination

    func loadMoreIfNeeded(currentMessage: Message) async {
        guard !isLoadingMore,
              let first = messages.first,
              first.id == currentMessage.id
        else { return }

        isLoadingMore = true
        defer { isLoadingMore = false }

        guard let oldestId = oldestMessageId else { return }
        do {
            let older = try await APIService.shared.fetchMessages(chatId: chatId, limit: 30, beforeId: oldestId)
            let sorted = older.sorted { $0.time < $1.time }
            messages = sorted + messages
            oldestMessageId = sorted.first?.id
        } catch {}
    }

    // MARK: - Send

    func send() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty || !selectedAttachments.isEmpty else { return }
        inputText = ""

        let finalText: String
        if encryptionEnabled {
            finalText = await ChatEncryptionService.shared.encrypt(text, chatId: chatId) ?? text
        } else {
            finalText = text
        }

        // Optimistic
        let tempId = "local_\(Date().timeIntervalSince1970)"
        let optimistic = Message(
            id: tempId, text: text, time: Int(Date().timeIntervalSince1970 * 1000),
            senderId: AccountManager.shared.currentUserId,
            status: "SENDING", cid: chatId
        )
        messages.append(optimistic)
        scrollToId = tempId

        let reply = replyToMessage
        replyToMessage = nil

        do {
            let sent = try await APIService.shared.sendMessage(
                chatId: chatId, text: finalText, replyToId: reply?.id
            )
            if let idx = messages.firstIndex(where: { $0.id == tempId }) {
                messages[idx] = sent
            }
            markLatestRead()
        } catch {
            await MessageQueueService.shared.enqueue(chatId: chatId, text: finalText)
            if let idx = messages.firstIndex(where: { $0.id == tempId }) {
                messages[idx] = messages[idx].copyWith(status: "FAILED")
            }
        }
    }

    func editMessage(_ message: Message, newText: String) async {
        do {
            try await APIService.shared.editMessage(messageId: message.id, chatId: chatId, newText: newText)
        } catch {}
    }

    func deleteMessage(_ message: Message) async {
        do {
            try await APIService.shared.deleteMessage(messageId: message.id, chatId: chatId)
        } catch {}
    }

    func react(to message: Message, emoji: String) async {
        do { try await APIService.shared.sendReaction(messageId: message.id, chatId: chatId, emoji: emoji) }
        catch {}
    }

    // MARK: - Typing

    func userStartedTyping() {
        // Notify server of typing event (opcode varies — send analytics heartbeat style)
        Task {
            try? await APIService.shared.sendMessage(
                opcode: 67, payload: ["chatId": chatId, "status": "TYPING"]
            )
        }
    }

    // MARK: - Encryption

    func toggleEncryption() {
        encryptionEnabled.toggle()
        ChatEncryptionService.shared.setEncryptionEnabled(encryptionEnabled, for: chatId)
    }

    // MARK: - Updates

    private func subscribeToUpdates() {
        APIService.shared.messagePublisher
            .filter { [weak self] $0.cid == self?.chatId }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.handleIncoming(message)
            }
            .store(in: &cancellables)

        ConnectionManager.shared.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] s in self?.connectionState = s }
            .store(in: &cancellables)
    }

    private func handleIncoming(_ message: Message) {
        if let idx = messages.firstIndex(where: { $0.id == message.id }) {
            messages[idx] = message
        } else {
            messages.append(message)
            scrollToId = message.id
            markLatestRead()
        }
    }

    private func markLatestRead() {
        guard let last = messages.last else { return }
        Task { try? await APIService.shared.markRead(chatId: chatId, messageId: last.id) }
    }
}
