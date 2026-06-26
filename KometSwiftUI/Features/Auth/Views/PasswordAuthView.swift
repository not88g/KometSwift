import SwiftUI

struct PasswordAuthView: View {
    @State private var password = ""
    @State private var isLoading = false
    @State private var error: String?
    @State private var hint: String?
    @State private var trackId = ""

    var body: some View {
        VStack(spacing: KometSpacing.xl) {
            Spacer()
            Image(systemName: "lock.fill")
                .resizable().scaledToFit()
                .frame(width: 64, height: 64)
                .foregroundStyle(.kometAccent)

            VStack(spacing: KometSpacing.sm) {
                Text(String(localized: "Enter your password"))
                    .font(.kometTitle)
                if let hint {
                    Text(String(localized: "Hint: \(hint)"))
                        .font(.kometCaption)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(spacing: KometSpacing.md) {
                SecureField(String(localized: "Password"), text: $password)
                    .textContentType(.password)
                    .padding(KometSpacing.md)
                    .background(Color(uiColor: .secondarySystemBackground),
                                in: RoundedRectangle(cornerRadius: KometSpacing.md, style: .continuous))

                if let err = error {
                    Text(err).font(.kometCaption).foregroundStyle(.red)
                }

                KometButton(String(localized: "Sign in"), isLoading: isLoading) {
                    Task { await submit() }
                }
                .disabled(password.isEmpty || isLoading)
            }
            .padding(.horizontal, KometSpacing.xl)

            Spacer()
        }
        .navigationTitle(String(localized: "Password"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            let data = APIService.shared  // hint/trackId set during OTP flow
        }
    }

    private func submit() async {
        isLoading = true
        error = nil
        do {
            try await APIService.shared.sendPassword(trackId: trackId, password: password)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
