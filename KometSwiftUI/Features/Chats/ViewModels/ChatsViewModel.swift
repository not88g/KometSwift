import Foundation
import Observation
import Combine

@Observable
final class ChatsViewModel {
    var chats: [Chat] = []
    var folders: [ChatFolder] = []
    var isLoading = false
    var navigationPath = NavigationPath()
    var connectionState: KometConnectionState = .idle

    private var cancellables = Set<AnyCancellable>()

    func load() async {
        isLoading = true
        defer { isLoading = false }

        // Show cache first
        chats = await ChatCacheService.shared.cachedChats()

        async let freshChats  = fetchChats()
        async let freshFolders = fetchFolders()

        let (c, f) = await (freshChats, freshFolders)
        chats   = c
        folders = f

        await ChatCacheService.shared.storeChats(c)
        subscribeToUpdates()
    }

    func filteredChats(folder: ChatFolder?, query: String) -> [Chat] {
        var result = chats

        if let folder {
            result = result.filter { folder.chatIds.contains($0.id) }
        }

        if !query.isEmpty {
            result = result.filter {
                $0.displayTitle.localizedCaseInsensitiveContains(query) ||
                $0.lastMessage.text.localizedCaseInsensitiveContains(query)
            }
        }

        return result.sorted { $0.lastMessage.time > $1.lastMessage.time }
    }

    private func fetchChats() async -> [Chat] {
        (try? await APIService.shared.fetchChats()) ?? []
    }

    private func fetchFolders() async -> [ChatFolder] {
        (try? await APIService.shared.fetchFolders()) ?? []
    }

    private func subscribeToUpdates() {
        // New / updated chat (last message changed, unread count changed)
        APIService.shared.chatsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] updated in
                guard let self else { return }
                for chat in updated { self.upsert(chat) }
            }
            .store(in: &cancellables)

        // New message arriving — update the relevant chat's lastMessage
        APIService.shared.messagePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                guard let self, let cid = message.cid else { return }
                if let idx = self.chats.firstIndex(where: { $0.id == cid }) {
                    self.chats[idx] = self.chats[idx].copyWith(lastMessage: message)
                }
            }
            .store(in: &cancellables)

        ConnectionManager.shared.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in self?.connectionState = state }
            .store(in: &cancellables)
    }

    private func upsert(_ chat: Chat) {
        if let idx = chats.firstIndex(where: { $0.id == chat.id }) {
            chats[idx] = chat
        } else {
            chats.insert(chat, at: 0)
        }
    }
}
