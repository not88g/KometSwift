import SwiftUI

struct PhoneEntryView: View {
    @State private var viewModel = PhoneEntryViewModel()
    @State private var navigationPath = NavigationPath()
    @Environment(\.kometUseLiquidGlass) private var useLiquidGlass

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                BackgroundGradient()

                VStack(spacing: KometSpacing.xl) {
                    Spacer()

                    // Logo
                    VStack(spacing: KometSpacing.md) {
                        Image(systemName: "message.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 72, height: 72)
                            .foregroundStyle(.kometAccent)

                        Text("Komet")
                            .font(.kometLarge)
                    }

                    Spacer()

                    // Card
                    VStack(spacing: KometSpacing.lg) {
                        Text(String(localized: "Your phone number"))
                            .font(.kometTitle)

                        Text(String(localized: "We'll send a confirmation code to this number"))
                            .font(.kometCaption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)

                        TextField(String(localized: "+7 (___) ___-__-__"), text: $viewModel.phone)
                            .keyboardType(.phonePad)
                            .textContentType(.telephoneNumber)
                            .font(.kometBody)
                            .padding(KometSpacing.md)
                            .background(Color(uiColor: .secondarySystemBackground),
                                        in: RoundedRectangle(cornerRadius: KometSpacing.md, style: .continuous))

                        if let err = viewModel.errorMessage {
                            Text(err)
                                .font(.kometCaption)
                                .foregroundStyle(.red)
                        }

                        KometButton(
                            String(localized: "Continue"),
                            isLoading: viewModel.isLoading
                        ) {
                            Task { await viewModel.submit() }
                        }
                        .disabled(!viewModel.canSubmit)
                    }
                    .padding(KometSpacing.xl)
                    .kometGlass()
                    .padding(.horizontal, KometSpacing.lg)

                    // TOS link
                    Button { navigationPath.append(NavigationDestination.tokenAuth) } label: {
                        Text(String(localized: "Sign in with token"))
                            .font(.kometCaption)
                            .foregroundStyle(.kometAccent)
                    }
                    .padding(.bottom, KometSpacing.lg)
                }
            }
            .navigationDestination(for: NavigationDestination.self) {
                AppNavigationStack.view(for: $0)
            }
            .onChange(of: viewModel.navigateTo) { _, dest in
                if let dest { navigationPath.append(dest) }
            }
        }
    }
}

private struct BackgroundGradient: View {
    var body: some View {
        LinearGradient(
            colors: [Color.kometAccent.opacity(0.15), Color(uiColor: .systemBackground)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}
