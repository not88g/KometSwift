import SwiftUI

struct RegistrationView: View {
    let trackId: String

    @State private var firstName = ""
    @State private var lastName  = ""
    @State private var isLoading = false
    @State private var error: String?
    @Environment(AppState.self) private var appState

    var canSubmit: Bool { !firstName.trimmingCharacters(in: .whitespaces).isEmpty && !isLoading }

    var body: some View {
        VStack(spacing: KometSpacing.xl) {
            Spacer()

            Image(systemName: "person.crop.circle.badge.plus")
                .resizable().scaledToFit()
                .frame(width: 72, height: 72)
                .foregroundStyle(.kometAccent)

            Text(String(localized: "Create your account"))
                .font(.kometTitle)

            VStack(spacing: KometSpacing.md) {
                TextField(String(localized: "First name"), text: $firstName)
                    .textContentType(.givenName)
                    .padding(KometSpacing.md)
                    .background(Color(uiColor: .secondarySystemBackground),
                                in: RoundedRectangle(cornerRadius: KometSpacing.md, style: .continuous))

                TextField(String(localized: "Last name"), text: $lastName)
                    .textContentType(.familyName)
                    .padding(KometSpacing.md)
                    .background(Color(uiColor: .secondarySystemBackground),
                                in: RoundedRectangle(cornerRadius: KometSpacing.md, style: .continuous))

                if let err = error {
                    Text(err).font(.kometCaption).foregroundStyle(.red)
                }

                KometButton(String(localized: "Create account"), isLoading: isLoading) {
                    Task { await register() }
                }
                .disabled(!canSubmit)
            }
            .padding(.horizontal, KometSpacing.xl)

            Spacer()
        }
        .navigationTitle(String(localized: "Registration"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func register() async {
        isLoading = true
        error = nil
        do {
            try await APIService.shared.register(
                firstName: firstName.trimmingCharacters(in: .whitespaces),
                lastName:  lastName.trimmingCharacters(in: .whitespaces),
                trackId:   trackId
            )
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
