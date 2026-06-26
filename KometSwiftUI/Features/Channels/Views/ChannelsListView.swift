import SwiftUI

struct ChannelsListView: View {
    @State private var channels: [Channel] = []
    @State private var isLoading = false
    @State private var searchText = ""

    var filtered: [Channel] {
        searchText.isEmpty ? channels : channels.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        List(filtered) { channel in
            HStack(spacing: KometSpacing.md) {
                AvatarView(baseUrl: channel.baseIconUrl, displayName: channel.title,
                           size: KometSpacing.avatarSizeLg)
                VStack(alignment: .leading, spacing: 2) {
                    Text(channel.title).font(.kometHeadline)
                    if let desc = channel.description {
                        Text(desc).font(.kometCaption).foregroundStyle(.secondary).lineLimit(1)
                    }
                    Text(String(localized: "\(channel.participantsCount) subscribers"))
                        .font(.kometCaption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if !channel.isSubscribed {
                    Button(String(localized: "Join")) {}
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .tint(.kometAccent)
                }
            }
            .listRowBackground(Color.clear)
        }
        .listStyle(.plain)
        .searchable(text: $searchText, prompt: String(localized: "Search channels"))
        .navigationTitle(String(localized: "Channels"))
        .overlay {
            if isLoading { ProgressView() }
        }
        .task { await load() }
    }

    private func load() async {
        isLoading = true
        // Channels are a subset of chats (type == CHANNEL) — filter from chat list
        let chats = (try? await APIService.shared.fetchChats()) ?? []
        channels = chats
            .filter { $0.type == "CHANNEL" }
            .map { chat in
                Channel(from: [
                    "id": chat.id as Any, "title": (chat.title ?? "") as Any,
                    "description": (chat.description ?? "") as Any,
                    "baseIconUrl": (chat.baseIconUrl ?? "") as Any,
                    "participantsCount": (chat.participantsCount ?? 0) as Any,
                    "isSubscribed": true as Any,
                ])
            }
        isLoading = false
    }
}
