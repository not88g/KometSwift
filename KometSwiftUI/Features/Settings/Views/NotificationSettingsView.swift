import SwiftUI

struct NotificationSettingsView: View {
    @State private var globalEnabled = true
    @State private var soundEnabled = true
    @State private var badgeEnabled = true
    @State private var inAppEnabled = true

    var body: some View {
        Form {
            Section(String(localized: "Global")) {
                Toggle(String(localized: "Notifications"), isOn: $globalEnabled)
                Toggle(String(localized: "Sound"),         isOn: $soundEnabled)
                Toggle(String(localized: "Badge"),         isOn: $badgeEnabled)
                Toggle(String(localized: "In-app banners"),isOn: $inAppEnabled)
            }

            Section(String(localized: "System")) {
                Button(String(localized: "Open system settings")) {
                    if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            }
        }
        .navigationTitle(String(localized: "Notifications"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            globalEnabled = UserDefaults.standard.bool(forKey: "notif_global") == false ? true : UserDefaults.standard.bool(forKey: "notif_global")
        }
        .onChange(of: globalEnabled) { _, v in UserDefaults.standard.set(v, forKey: "notif_global") }
    }
}
