import SwiftUI

struct GroupSettingsView: View {
    let chatId: Int

    @State private var chat: Chat?
    @State private var participants: [Contact] = []
    @State private var isLoading = false
    @State private var title = ""
    @State private var description = ""
    @Environment(AppState.self) private var appState

    var body: some View {
        Form {
            Section {
                HStack {
                    Spacer()
                    AvatarView(baseUrl: chat?.baseIconUrl, displayName: title, size: 80)
                    Spacer()
                }
            }
            .listRowBackground(Color.clear)

            Section(String(localized: "Group Info")) {
                TextField(String(localized: "Group name"), text: $title)
                TextField(String(localized: "Description"), text: $description)
            }

            Section(String(localized: "Members (\(participants.count))")) {
                ForEach(participants) { member in
                    HStack {
                        AvatarView(baseUrl: member.photoBaseUrl, displayName: member.name,
                                   size: KometSpacing.avatarSizeSm)
                        Text(member.name)
                        Spacer()
                        if member.id == chat?.ownerId {
                            Text(String(localized: "Admin"))
                                .font(.kometCaption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        if appState.currentUserId == chat?.ownerId && member.id != appState.currentUserId {
                            Button(role: .destructive) {
                                Task { try? await APIService.shared.kickParticipant(chatId: chatId, userId: member.id) }
                            } label: {
                                Label(String(localized: "Remove"), systemImage: "person.fill.xmark")
                            }
                        }
                    }
                }
            }

            if appState.currentUserId != chat?.ownerId {
                Section {
                    Button(String(localized: "Leave Group"), role: .destructive) {
                        Task { try? await APIService.shared.leaveGroup(chatId: chatId) }
                    }
                }
            }
        }
        .navigationTitle(String(localized: "Group Settings"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(String(localized: "Save")) { Task { await save() } }
                    .fontWeight(.semibold)
            }
        }
        .task { await load() }
    }

    private func load() async {
        isLoading = true
        participants = (try? await APIService.shared.fetchGroupParticipants(chatId: chatId)) ?? []
        isLoading = false
    }

    private func save() async {
        try? await APIService.shared.updateGroupSettings(chatId: chatId, title: title, description: description)
    }
}
