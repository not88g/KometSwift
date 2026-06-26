import SwiftUI

struct ContactSelectionView: View {
    @State private var contacts: [Contact] = []
    @State private var selected: Set<Int> = []
    @State private var groupTitle = ""
    @State private var isCreating = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TextField(String(localized: "Group name"), text: $groupTitle)
                    .padding(KometSpacing.md)
                    .background(Color(uiColor: .secondarySystemBackground))
                    .padding(KometSpacing.md)

                List(contacts) { contact in
                    HStack {
                        AvatarView(baseUrl: contact.photoBaseUrl, displayName: contact.name,
                                   size: KometSpacing.avatarSizeMd)
                        Text(contact.name).font(.kometHeadline)
                        Spacer()
                        if selected.contains(contact.id) {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(.kometAccent)
                        } else {
                            Image(systemName: "circle").foregroundStyle(.secondary)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if selected.contains(contact.id) { selected.remove(contact.id) }
                        else { selected.insert(contact.id) }
                    }
                    .listRowBackground(Color.clear)
                }
                .listStyle(.plain)
            }
            .navigationTitle(String(localized: "New Group"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(String(localized: "Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "Create")) {
                        Task { await createGroup() }
                    }
                    .disabled(selected.isEmpty || groupTitle.isEmpty || isCreating)
                    .fontWeight(.semibold)
                }
            }
            .task {
                contacts = (try? await APIService.shared.fetchContacts()) ?? []
            }
        }
    }

    private func createGroup() async {
        isCreating = true
        _ = try? await APIService.shared.createGroupChat(
            title: groupTitle,
            participantIds: Array(selected)
        )
        isCreating = false
        dismiss()
    }
}
