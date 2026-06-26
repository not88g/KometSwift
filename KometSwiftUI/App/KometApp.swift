import SwiftUI

@main
struct KometApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .environment(\.kometUseLiquidGlass, appState.useLiquidGlass)
                .preferredColorScheme(appState.colorScheme)
                .onOpenURL { url in DeepLinkHandler.shared.handle(url, appState: appState) }
        }
    }
}

struct RootView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Group {
            if appState.isBootstrapping {
                SplashView()
            } else if appState.isAuthenticated {
                ChatsView()
            } else {
                PhoneEntryView()
            }
        }
        .task { await appState.bootstrap() }
        .animation(.easeInOut(duration: 0.3), value: appState.isAuthenticated)
        .animation(.easeInOut(duration: 0.2), value: appState.isBootstrapping)
    }
}

struct SplashView: View {
    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground).ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "message.fill")
                    .resizable()
                    .frame(width: 64, height: 64)
                    .foregroundStyle(.kometAccent)
                Text("Komet")
                    .font(.largeTitle.bold())
                ProgressView()
            }
        }
    }
}
