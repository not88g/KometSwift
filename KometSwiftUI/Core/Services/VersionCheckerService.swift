import Foundation

actor VersionCheckerService {
    static let shared = VersionCheckerService()

    private let releaseUrl = "https://api.github.com/repos/KometTeam/Komet/releases/latest"

    struct ReleaseInfo {
        let version: String
        let downloadUrl: String
        let releaseNotes: String
    }

    func checkForUpdates() async -> ReleaseInfo? {
        guard let url = URL(string: releaseUrl) else { return nil }
        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }

        let tag     = json["tag_name"] as? String ?? ""
        let notes   = json["body"] as? String ?? ""
        let assets  = json["assets"] as? [[String: Any]] ?? []
        let ipa     = assets.first(where: { ($0["name"] as? String)?.hasSuffix(".ipa") == true })
        let url2    = ipa?["browser_download_url"] as? String ?? ""

        guard !tag.isEmpty else { return nil }
        return ReleaseInfo(version: tag, downloadUrl: url2, releaseNotes: notes)
    }

    var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }
}
