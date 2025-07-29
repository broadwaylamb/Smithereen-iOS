import SwiftUI
import SwiftUIIntrospect

struct SettingsView: View {
    let api: any AuthenticationService
    @EnvironmentObject private var paletteHolder: PaletteHolder
    @AppStorage(.roundProfilePictures) private var roundProfilePictures: Bool

    var body: some View {
        List {
            Section {
                AreYouSureButton(
                    title: "Erase cache",
                    confirmationTitle: "Erase",
                    confirmationRole: .destructive,
                ) {
                    URLCache.smithereenMediaCache.removeAllCachedResponses()
                }
            } header: {
                Text("Cache", comment: "Section title in settings")
            } footer: {
                Text(
                    "Deletes all media from cache",
                    comment: "Explainer section footer in settings"
                )
            }
            Section(header: Text("Appearance")) {
                Toggle("Round profile pictures", isOn: $roundProfilePictures)
                MenuPicker("Color theme", selection: $paletteHolder.palette) {
                    ForEach(Palette.allCases) { palette in
                        Text(verbatim: palette.name)
                            .tag(palette)
                    }
                }
            }
            Section {
                AreYouSureButton(
                    title: "Sign out",
                    confirmationTitle: "Sign out",
                    role: .destructive,
                    confirmationRole: .destructive
                ) {
                    api.logOut()
                }
            }
        }
        .tint(nil)
        .listStyle(.grouped)
        .colorScheme(.light)
    }
}

private struct AreYouSureButton: View {
    var title: LocalizedStringKey
    var confirmationTitle: LocalizedStringKey
    var role: ButtonRole?
    var confirmationRole: ButtonRole?
    var action: () -> Void

    @State private var confirmationPresented: Bool = false

    var body: some View {
        Button(title, role: role) {
            confirmationPresented = true
        }
        .tint(.black)
        .frame(maxWidth: .infinity, alignment: .center)
        .confirmationDialog(
            "Are you sure?",
            isPresented: $confirmationPresented,
            titleVisibility: .visible,
        ) {
            Button(confirmationTitle, role: confirmationRole, action: action)
        }
        .colorScheme(.light)
    }
}

#Preview("Settings") {
    SettingsView(api: MockApi())
        .environmentObject(PaletteHolder())
}
