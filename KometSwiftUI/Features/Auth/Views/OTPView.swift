import SwiftUI

struct OTPView: View {
    let token: String
    let phone: String

    @State private var viewModel: OTPViewModel
    @Environment(AppState.self) private var appState

    init(token: String, phone: String) {
        self.token = token
        self.phone = phone
        self._viewModel = State(initialValue: OTPViewModel(token: token, phone: phone))
    }

    var body: some View {
        VStack(spacing: KometSpacing.xl) {
            Spacer()

            Image(systemName: "lock.shield.fill")
                .resizable().scaledToFit()
                .frame(width: 64, height: 64)
                .foregroundStyle(.kometAccent)

            VStack(spacing: KometSpacing.sm) {
                Text(String(localized: "Enter the code"))
                    .font(.kometTitle)
                Text(String(localized: "Sent to \(phone)"))
                    .font(.kometCaption)
                    .foregroundStyle(.secondary)
            }

            // 4-digit code entry using individual fields
            OTPFieldView(code: $viewModel.code, length: 4)
                .padding(.horizontal, KometSpacing.xl)

            if let err = viewModel.errorMessage {
                Text(err).font(.kometCaption).foregroundStyle(.red)
            }

            KometButton(String(localized: "Verify"), isLoading: viewModel.isLoading) {
                Task { await viewModel.submit() }
            }
            .disabled(!viewModel.canSubmit)
            .padding(.horizontal, KometSpacing.xl)

            Button { Task { await resendCode() } } label: {
                Text(String(localized: "Resend code"))
                    .font(.kometCaption)
                    .foregroundStyle(.kometAccent)
            }

            Spacer()
        }
        .navigationTitle(String(localized: "Verification"))
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: viewModel.navigateTo) { _, dest in
            if dest == nil {
                // navigateTo nil means auth succeeded — AppState handles the gate
            }
        }
    }

    private func resendCode() async {
        viewModel.isLoading = true
        try? await APIService.shared.requestOtp(phone, resend: true)
        viewModel.isLoading = false
    }
}

// MARK: - Simple OTP digit field

struct OTPFieldView: View {
    @Binding var code: String
    let length: Int

    @FocusState private var focused: Bool

    var body: some View {
        ZStack {
            // Hidden actual text field
            TextField("", text: $code)
                .keyboardType(.numberPad)
                .focused($focused)
                .frame(width: 1, height: 1)
                .opacity(0.01)
                .onChange(of: code) { _, v in
                    if v.count > length { code = String(v.prefix(length)) }
                }

            // Visual digit boxes
            HStack(spacing: KometSpacing.md) {
                ForEach(0..<length, id: \.self) { i in
                    let char = code.count > i ? String(Array(code)[i]) : ""
                    ZStack {
                        RoundedRectangle(cornerRadius: KometSpacing.sm, style: .continuous)
                            .fill(Color(uiColor: .secondarySystemBackground))
                            .frame(width: 52, height: 60)
                            .overlay(
                                RoundedRectangle(cornerRadius: KometSpacing.sm, style: .continuous)
                                    .stroke(focused && code.count == i ? Color.kometAccent : Color.clear, lineWidth: 2)
                            )
                        Text(char)
                            .font(.system(size: 28, weight: .semibold))
                    }
                }
            }
        }
        .onTapGesture { focused = true }
        .onAppear { focused = true }
    }
}
