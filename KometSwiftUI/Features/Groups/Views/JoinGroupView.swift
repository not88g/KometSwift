import SwiftUI

struct JoinGroupView: View {
    @State private var link = ""
    @State private var isJoining = false
    @State private var error: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: KometSpacing.xl) {
                Image(systemName: "person.3.fill")
                    .resizable().scaledToFit()
                    .frame(width: 72, height: 48)
                    .foregroundStyle(.kometAccent)

                Text(String(localized: "Join a Group"))
                    .font(.kometTitle)

                Text(String(localized: "Enter the invite link or ID"))
                    .font(.kometCaption)
                    .foregroundStyle(.secondary)

                TextField("https://max.ru/join/...", text: $link)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .padding(KometSpacing.md)
                    .background(Color(uiColor: .secondarySystemBackground),
                                in: RoundedRectangle(cornerRadius: KometSpacing.md, style: .continuous))
                    .padding(.horizontal, KometSpacing.xl)

                if let err = error {
                    Text(err).font(.kometCaption).foregroundStyle(.red)
                }

                KometButton(String(localized: "Join"), isLoading: isJoining) {
                    Task { await join() }
                }
                .padding(.horizontal, KometSpacing.xl)
                .disabled(link.trimmingCharacters(in: .whitespaces).isEmpty || isJoining)

                Spacer()
            }
            .padding(.top, KometSpacing.xl)
            .navigationTitle(String(localized: "Join Group"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(String(localized: "Cancel")) { dismiss() }
                }
            }
        }
    }

    private func join() async {
        isJoining = true
        error = nil
        do {
            _ = try await APIService.shared.joinGroupByLink(link: link.trimmingCharacters(in: .whitespaces))
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
        isJoining = false
    }
}
