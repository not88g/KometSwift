import SwiftUI

struct AboutView: View {
    @State private var latestRelease: String?

    var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }

    var body: some View {
        List {
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: KometSpacing.sm) {
                        Image(systemName: "message.fill")
                            .resizable().scaledToFit()
                            .frame(width: 64, height: 64)
                            .foregroundStyle(.kometAccent)
                        Text("Komet").font(.kometTitle)
                        Text("v\(version)").font(.kometCaption).foregroundStyle(.secondary)
                        if let latest = latestRelease {
                            Text(String(localized: "Latest: \(latest)"))
                                .font(.kometCaption2).foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                }
                .listRowBackground(Color.clear)
                .padding(.vertical, KometSpacing.md)
            }

            Section(String(localized: "Links")) {
                Link(String(localized: "Telegram Channel"), destination: URL(string: AppConstants.telegramChannel)!)
                Link(String(localized: "Source Code"), destination: URL(string: "https://github.com/KometTeam/Komet")!)
                Link(String(localized: "Terms of Service"), destination: URL(string: AppConstants.legalUrl)!)
            }

            Section(String(localized: "Credits")) {
                Text(String(localized: "Komet is a FOSS client for MAX Messenger.\nBuilt with ❤️ by the Komet Team."))
                    .font(.kometCaption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(String(localized: "About Komet"))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            latestRelease = await VersionCheckerService.shared.checkForUpdates()?.version
        }
    }
}
