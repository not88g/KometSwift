import SwiftUI

struct SessionSpoofingView: View {
    @State private var config = SpoofingConfig(
        enabled: false, userAgent: "", deviceName: "", osVersion: "",
        screen: "", timezone: "", locale: "", deviceId: "", deviceType: "ANDROID", appVersion: "25.21.3"
    )

    var body: some View {
        Form {
            Section {
                Toggle(String(localized: "Enable Spoofing"), isOn: $config.enabled)
            } footer: {
                Text(String(localized: "Presents the app as an Android device to the server. Changing this may disconnect your current session."))
            }

            if config.enabled {
                Section(String(localized: "Presets")) {
                    ForEach(DevicePresets.androidPresets, id: \.deviceName) { preset in
                        Button {
                            config.userAgent  = preset.userAgent
                            config.deviceName = preset.deviceName
                            config.osVersion  = preset.osVersion
                            config.screen     = preset.screen
                        } label: {
                            Text(preset.deviceName)
                        }
                    }
                }

                Section(String(localized: "Manual")) {
                    TextField(String(localized: "User Agent"), text: $config.userAgent, axis: .vertical)
                        .lineLimit(3)
                    TextField(String(localized: "Device Name"),  text: $config.deviceName)
                    TextField(String(localized: "OS Version"),   text: $config.osVersion)
                    TextField(String(localized: "Screen"),       text: $config.screen)
                    TextField(String(localized: "App Version"),  text: $config.appVersion)
                    TextField(String(localized: "Device ID"),    text: $config.deviceId)
                }

                Section {
                    Button(String(localized: "Generate new Device ID")) {
                        config.deviceId = UUID().uuidString
                    }
                }
            }
        }
        .navigationTitle(String(localized: "Session Spoofing"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(String(localized: "Save")) {
                    Task { await SpoofingService.shared.saveConfig(config) }
                }
                .fontWeight(.semibold)
            }
        }
        .onAppear {
            config = SpoofingService.shared.currentConfig
        }
    }
}
