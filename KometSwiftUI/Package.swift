// swift-tools-version: 5.9
// NOTE: This Package.swift is provided as a reference for dependency resolution only.
// The actual Xcode project (.xcodeproj) is the authoritative build definition.
// To set up a new Xcode project:
//   1. Open Xcode → File → New → Project → App (iOS)
//   2. Product name: Komet, Bundle ID: your.bundle.id, Minimum Deployment: iOS 16.0
//   3. Drag the KometSwiftUI/ folder into the project navigator (uncheck "Copy items if needed" if already in place)
//   4. In "Signing & Capabilities": add Push Notifications, Associated Domains (applinks:max.ru)
//   5. Link system frameworks: libcompression.tbd (for LZ4), Network.framework, CryptoKit (auto)
//   6. Set CFBundleURLTypes and usage strings from Resources/Info.plist
//
// No third-party Swift packages are required.
// All networking uses Network.framework (NWConnection).
// Compression uses system libcompression (COMPRESSION_LZ4_RAW) — add libcompression.tbd in Build Phases → Link Binary.
// Cryptography uses CryptoKit (system, no extra linking needed on iOS 13+).

import PackageDescription

let package = Package(
    name: "Komet",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "Komet", targets: ["Komet"])
    ],
    targets: [
        .target(
            name: "Komet",
            path: ".",
            exclude: ["Resources/Info.plist", "Package.swift"],
            sources: [
                "App",
                "Core",
                "DesignSystem",
                "Features",
                "Navigation",
                "Persistence"
            ],
            resources: [
                .process("Resources")
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ],
            linkerSettings: [
                .linkedLibrary("compression")
            ]
        )
    ]
)
