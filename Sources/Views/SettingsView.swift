import SwiftUI

struct SettingsView: View {
    let api: any AuthenticationService
    @EnvironmentObject private var paletteHolder: PaletteHolder

    var body: some View {
        List {
            Section(header: Text("Appearance")) {
                Picker("Color theme", selection: $paletteHolder.palette) {
                    ForEach(Palette.allCases) { palette in
                        Text(verbatim: palette.name)
                            .tag(palette)
                    }
                }

            }
            Section {
                Button("Sign out", role: .destructive) {
                    api.logOut()
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .listStyle(.grouped)
        .colorScheme(.light)
    }
}

#Preview("Settings") {
    SettingsView(api: MockApi())
}
