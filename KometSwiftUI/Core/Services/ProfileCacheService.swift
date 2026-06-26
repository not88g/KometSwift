import Foundation

actor ProfileCacheService {
    static let shared = ProfileCacheService()

    private var profiles: [Int: Profile] = [:]

    func initialize() async {
        profiles = await CacheService.shared.load([Int: Profile].self, forKey: "profiles") ?? [:]
    }

    func profile(for userId: Int) -> Profile? { profiles[userId] }

    func store(_ profile: Profile) async {
        profiles[profile.id] = profile
        await CacheService.shared.store(profiles, forKey: "profiles")
    }

    func clearAll() async {
        profiles = [:]
        await CacheService.shared.remove(forKey: "profiles")
    }
}
