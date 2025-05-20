import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var paletteState: PaletteState

    var body: some View {
        List {
            Section(header: Text("Appearance")) {
                Picker("Color theme", selection: $paletteState.palette) {
                    ForEach(Palette.allCases) { palette in
                        Text(palette.name)
                            .tag(palette)
                    }
                }

            }
        }
        .listStyle(.grouped)
        .colorScheme(.light)
    }
}

@available(iOS 17.0, *)
#Preview("Settings") {
    @Previewable @StateObject var paletteState = PaletteState()
    SettingsView()
        .environmentObject(paletteState)
        .environment(\.palette, paletteState.palette)
}
