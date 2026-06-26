// Mirrors lib/utils/device_presets.dart — a catalogue of Android device fingerprints.

import Foundation

struct DevicePreset {
    let deviceName: String
    let osVersion: String
    let userAgent: String
    let screen: String
    let deviceType: String
}

enum DevicePresets {
    static let androidPresets: [DevicePreset] = [
        DevicePreset(
            deviceName: "Samsung Galaxy S24",
            osVersion: "14",
            userAgent: "Mozilla/5.0 (Linux; Android 14; SM-S921B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36",
            screen: "1080x2340",
            deviceType: "ANDROID"
        ),
        DevicePreset(
            deviceName: "Google Pixel 8",
            osVersion: "14",
            userAgent: "Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36",
            screen: "1080x2400",
            deviceType: "ANDROID"
        ),
        DevicePreset(
            deviceName: "Xiaomi 14",
            osVersion: "14",
            userAgent: "Mozilla/5.0 (Linux; Android 14; 2401129C) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36",
            screen: "1080x2400",
            deviceType: "ANDROID"
        ),
        DevicePreset(
            deviceName: "OnePlus 12",
            osVersion: "14",
            userAgent: "Mozilla/5.0 (Linux; Android 14; CPH2573) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36",
            screen: "1440x3168",
            deviceType: "ANDROID"
        ),
        DevicePreset(
            deviceName: "Samsung Galaxy A55",
            osVersion: "14",
            userAgent: "Mozilla/5.0 (Linux; Android 14; SM-A556B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36",
            screen: "1080x2340",
            deviceType: "ANDROID"
        ),
    ]
}
