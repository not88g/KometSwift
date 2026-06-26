import SwiftUI

struct AppearanceSettingsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var state = appState
        Form {
            Section(String(localized: "Color Scheme")) {
                Picker(String(localized: "Theme"), selection: $state.colorScheme) {
                    Text(String(localized: "System")).tag(Optional<ColorScheme>.none)
                    Text(String(localized: "Light")) .tag(Optional<ColorScheme>.some(.light))
                    Text(String(localized: "Dark"))  .tag(Optional<ColorScheme>.some(.dark))
                }
                .pickerStyle(.segmented)
            }

            Section {
                Toggle(isOn: $state.useLiquidGlass) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(String(localized: "Liquid Glass"))
                            if #unavailable(iOS 26) {
                                Text(String(localized: "Requires iOS 26"))
                                    .font(.kometCaption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } icon: {
                        Image(systemName: "sparkles")
                    }
                }
                .disabled({
                    if #available(iOS 26, *) { return false }
                    return true
                }())
            } header: {
                Text(String(localized: "Visual Style"))
            } footer: {
                Text(String(localized: "Uses native iOS 26 Liquid Glass materials. Disable for a classic look on older iOS versions."))
            }
        }
        .navigationTitle(String(localized: "Appearance"))
        .navigationBarTitleDisplayMode(.inline)
    }
}
