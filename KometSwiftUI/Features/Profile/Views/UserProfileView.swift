import SwiftUI

struct UserProfileView: View {
    let userId: Int

    @State private var contact: Contact?
    @State private var isLoading = true
    @State private var showComplaintSheet = false
    @Environment(AppState.self) private var appState

    var body: some View {
        ScrollView {
            VStack(spacing: KometSpacing.xl) {
                // Avatar
                AvatarView(
                    baseUrl: contact?.photoBaseUrl,
                    displayName: contact?.name ?? "",
                    size: 100
                )
                .padding(.top, KometSpacing.xl)

                // Name & status
                VStack(spacing: KometSpacing.sm) {
                    Text(contact?.name ?? "")
                        .font(.kometTitle)
                    if let desc = contact?.description, !desc.isEmpty {
                        Text(desc)
                            .font(.kometCaption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    // Online indicator
                    HStack(spacing: 4) {
                        PresenceDotView(isOnline: contact?.isOnline ?? false)
                        Text(contact?.isOnline == true
                             ? String(localized: "Online")
                             : String(localized: "Offline"))
                            .font(.kometCaption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Actions
                HStack(spacing: KometSpacing.xl) {
                    actionButton(icon: "message.fill",  label: String(localized: "Message")) { openChat() }
                    if contact?.isUserBlocked == false {
                        actionButton(icon: "nosign",    label: String(localized: "Block"))   { Task { await block() } }
                    } else {
                        actionButton(icon: "checkmark.circle", label: String(localized: "Unblock")) { Task { await unblock() } }
                    }
                    actionButton(icon: "flag.fill",     label: String(localized: "Report"))  { showComplaintSheet = true }
                }
                .padding(.horizontal, KometSpacing.lg)
            }
            .padding(KometSpacing.lg)
        }
        .navigationTitle(contact?.name ?? String(localized: "Profile"))
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if isLoading { ProgressView() }
        }
        .sheet(isPresented: $showComplaintSheet) {
            ComplaintView(targetUserId: userId)
        }
        .task { await load() }
    }

    private func actionButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundStyle(.kometAccent)
                Text(label)
                    .font(.kometCaption2)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 70, height: 60)
            .background(Color(uiColor: .secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: KometSpacing.sm, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func load() async {
        isLoading = true
        contact = try? await APIService.shared.fetchContact(userId: userId)
        isLoading = false
    }

    private func openChat() { /* push chat via NavigationPath */ }

    private func block() async {
        try? await APIService.shared.blockContact(userId: userId)
        await load()
    }

    private func unblock() async {
        try? await APIService.shared.unblockContact(userId: userId)
        await load()
    }
}

struct ComplaintView: View {
    let targetUserId: Int?
    let targetMessageId: String? = nil
    let targetChatId: Int? = nil

    @State private var selectedType: ComplaintType = .spam
    @State private var reason = ""
    @State private var isSending = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section(String(localized: "Reason")) {
                    Picker(String(localized: "Type"), selection: $selectedType) {
                        ForEach(ComplaintType.allCases, id: \.self) {
                            Text($0.displayName).tag($0)
                        }
                    }
                }
                Section(String(localized: "Details (optional)")) {
                    TextEditor(text: $reason)
                        .frame(height: 80)
                }
            }
            .navigationTitle(String(localized: "Report"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(String(localized: "Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "Send")) {
                        Task { await send() }
                    }
                    .fontWeight(.semibold)
                    .disabled(isSending)
                }
            }
        }
    }

    private func send() async {
        isSending = true
        let data = ComplaintData(
            type: selectedType,
            reason: reason.isEmpty ? nil : reason,
            targetUserId: targetUserId,
            targetMessageId: targetMessageId,
            targetChatId: targetChatId
        )
        try? await APIService.shared.sendComplaint(data)
        isSending = false
        dismiss()
    }
}
