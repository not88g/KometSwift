import SwiftUI

struct SearchChannelsView: View {
    @State private var query = ""
    @State private var results: [Chat] = []
    @State private var isSearching = false

    var body: some View {
        List(results) { chat in
            NavigationLink(value: NavigationDestination.chat(chatId: chat.id)) {
                HStack {
                    AvatarView(baseUrl: chat.baseIconUrl, displayName: chat.displayTitle,
                               size: KometSpacing.avatarSizeMd)
                    VStack(alignment: .leading) {
                        Text(chat.displayTitle).font(.kometHeadline)
                        if let desc = chat.description, !desc.isEmpty {
                            Text(desc).font(.kometCaption).foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        if let count = chat.participantsCount {
                            Text(String(localized: "\(count) subscribers"))
                                .font(.kometCaption2).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle(String(localized: "Search Channels"))
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $query, prompt: String(localized: "Channel name or link"))
        .onSubmit(of: .search) { Task { await search() } }
        .overlay {
            if isSearching { ProgressView() }
            else if results.isEmpty && !query.isEmpty {
                ContentUnavailableView.search(text: query)
            }
        }
        .navigationDestination(for: NavigationDestination.self) {
            AppNavigationStack.view(for: $0)
        }
    }

    private func search() async {
        guard !query.isEmpty else { return }
        isSearching = true
        do {
            let contacts = try await APIService.shared.searchContacts(query: query)
            results = contacts.compactMap { contact -> Chat? in
                guard contact.isBot else { return nil }
                return nil
            }
        } catch {}
        isSearching = false
    }
}
