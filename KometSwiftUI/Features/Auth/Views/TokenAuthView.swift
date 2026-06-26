import SwiftUI

struct TokenAuthView: View {
    @State private var token = ""
    @State private var isLoading = false
    @State private var error: String?
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: KometSpacing.xl) {
            Spacer()
            Image(systemName: "key.fill")
                .resizable().scaledToFit()
                .frame(width: 64, height: 64)
                .foregroundStyle(.kometAccent)

            Text(String(localized: "Enter your token"))
                .font(.kometTitle)

            VStack(spacing: KometSpacing.md) {
                TextField(String(localized: "Paste your auth token"), text: $token)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(KometSpacing.md)
                    .background(Color(uiColor: .secondarySystemBackground),
                                in: RoundedRectangle(cornerRadius: KometSpacing.md, style: .continuous))

                if let err = error {
                    Text(err).font(.kometCaption).foregroundStyle(.red)
                }

                KometButton(String(localized: "Sign in"), isLoading: isLoading) {
                    Task { await signIn() }
                }
                .disabled(token.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
            }
            .padding(.horizontal, KometSpacing.xl)
            Spacer()
        }
        .navigationTitle(String(localized: "Token auth"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func signIn() async {
        isLoading = true
        error = nil
        do {
            try await APIService.shared.loginWithToken(token.trimmingCharacters(in: .whitespaces))
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
