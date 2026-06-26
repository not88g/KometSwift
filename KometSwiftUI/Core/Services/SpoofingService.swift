// Mirrors _generateInitialAndroidSpoof() from main.dart exactly.
// On first launch generates a random Android device fingerprint stored in UserDefaults.
// This must match the Flutter key names so that users migrating keep their spoofing config.

import Foundation

actor SpoofingService {
    static let shared = SpoofingService()

    func generateIfNeeded() async {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: "spoofing_enabled") else { return }

        let presets = DevicePresets.androidPresets
        guard let preset = presets.randomElement() else { return }

        let deviceId = UUID().uuidString
        let timezone = TimeZone.current.identifier
        let locale = Locale.current.language.languageCode?.identifier ?? "ru"

        defaults.set(true,               forKey: "spoofing_enabled")
        defaults.set(true,               forKey: "anonymity_enabled")
        defaults.set(preset.userAgent,   forKey: "spoof_useragent")
        defaults.set(preset.deviceName,  forKey: "spoof_devicename")
        defaults.set(preset.osVersion,   forKey: "spoof_osversion")
        defaults.set(preset.screen,      forKey: "spoof_screen")
        defaults.set(timezone,           forKey: "spoof_timezone")
        defaults.set(locale,             forKey: "spoof_locale")
        defaults.set(deviceId,           forKey: "spoof_deviceid")
        defaults.set("ANDROID",          forKey: "spoof_devicetype")
        defaults.set("25.21.3",          forKey: "spoof_appversion")
    }

    var isEnabled: Bool { UserDefaults.standard.bool(forKey: "spoofing_enabled") }

    var currentConfig: SpoofingConfig {
        let d = UserDefaults.standard
        return SpoofingConfig(
            enabled:     d.bool(forKey: "spoofing_enabled"),
            userAgent:   d.string(forKey: "spoof_useragent") ?? "",
            deviceName:  d.string(forKey: "spoof_devicename") ?? "",
            osVersion:   d.string(forKey: "spoof_osversion") ?? "",
            screen:      d.string(forKey: "spoof_screen") ?? "",
            timezone:    d.string(forKey: "spoof_timezone") ?? TimeZone.current.identifier,
            locale:      d.string(forKey: "spoof_locale") ?? "ru",
            deviceId:    d.string(forKey: "spoof_deviceid") ?? UUID().uuidString,
            deviceType:  d.string(forKey: "spoof_devicetype") ?? "ANDROID",
            appVersion:  d.string(forKey: "spoof_appversion") ?? "25.21.3"
        )
    }

    func saveConfig(_ config: SpoofingConfig) {
        let d = UserDefaults.standard
        d.set(config.enabled,    forKey: "spoofing_enabled")
        d.set(config.userAgent,  forKey: "spoof_useragent")
        d.set(config.deviceName, forKey: "spoof_devicename")
        d.set(config.osVersion,  forKey: "spoof_osversion")
        d.set(config.screen,     forKey: "spoof_screen")
        d.set(config.timezone,   forKey: "spoof_timezone")
        d.set(config.locale,     forKey: "spoof_locale")
        d.set(config.deviceId,   forKey: "spoof_deviceid")
        d.set(config.deviceType, forKey: "spoof_devicetype")
        d.set(config.appVersion, forKey: "spoof_appversion")
    }

    func buildUserAgentPayload() -> [String: Any] {
        let c = currentConfig
        return [
            "useragent":   c.userAgent,
            "devicename":  c.deviceName,
            "osversion":   c.osVersion,
            "screen":      c.screen,
            "timezone":    c.timezone,
            "locale":      c.locale,
            "deviceid":    c.deviceId,
            "devicetype":  c.deviceType,
            "appversion":  c.appVersion,
        ]
    }
}

struct SpoofingConfig: Codable {
    var enabled: Bool
    var userAgent: String
    var deviceName: String
    var osVersion: String
    var screen: String
    var timezone: String
    var locale: String
    var deviceId: String
    var deviceType: String
    var appVersion: String
}
