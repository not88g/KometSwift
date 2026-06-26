import SwiftUI

struct ContactSearchView: View {
    let mode: ContactSearchMode

    @State private var query = ""
    @State private var contacts: [Contact] = []
    @State private var isLoading = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            if isLoading {
                ProgressView().frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
            }
            ForEach(contacts) { contact in
                contactRow(contact)
                    .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .searchable(text: $query, prompt: String(localized: "Search contacts"))
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: query) { _, q in
            Task { await search(q) }
        }
        .task { await loadInitial() }
    }

    private var title: String {
        switch mode {
        case .newChat:          return String(localized: "New Chat")
        case .search:           return String(localized: "Search")
        case .addToGroup:       return String(localized: "Add Member")
        }
    }

    private func contactRow(_ contact: Contact) -> some View {
        HStack(spacing: KometSpacing.md) {
            AvatarView(
                baseUrl: contact.photoBaseUrl,
                displayName: contact.name,
                size: KometSpacing.avatarSizeMd,
                showPresence: true,
                isOnline: contact.isOnline
            )
            VStack(alignment: .leading, spacing: 2) {
                Text(contact.name).font(.kometHeadline)
                if let desc = contact.description {
                    Text(desc).font(.kometCaption).foregroundStyle(.secondary).lineLimit(1)
                }
            }
            Spacer()
            if contact.isBot {
                Text("BOT")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color.kometAccent, in: Capsule())
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { handleSelect(contact) }
    }

    private func handleSelect(_ contact: Contact) {
        switch mode {
        case .newChat:
            // Open chat — push via NavigationPath
            break
        case .addToGroup(let chatId):
            Task { try? await APIService.shared.joinGroupByLink(link: "\(chatId)") }
            dismiss()
        case .search:
            break
        }
    }

    private func loadInitial() async {
        isLoading = true
        contacts = (try? await APIService.shared.fetchContacts()) ?? []
        isLoading = false
    }

    private func search(_ q: String) async {
        guard !q.isEmpty else {
            await loadInitial()
            return
        }
        isLoading = true
        contacts = (try? await APIService.shared.searchContacts(query: q)) ?? []
        isLoading = false
    }
}
