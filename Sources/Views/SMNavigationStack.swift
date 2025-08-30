import SwiftUI

struct SMNavigationStack<Content: View>: View {
    @ViewBuilder var content: () -> Content

    @State var path = NavigationPath()
    @EnvironmentObject private var palette: PaletteHolder

    @Environment(\.isSlideableMenuFixed) private var isSlideableMenuFixed
    @Environment(\.toggleSlideableMenu) private var toggleSlideableMenu

    var body: some View {
        NavigationStack(path: $path) {
            content()
                .navigationBarStyleSmithereen()
                .environment(\.pushToNavigationStack) { item in
                    path.append(item)
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        if !isSlideableMenuFixed {
                            Button(action: toggleSlideableMenu.callAsFunction) {
                                Image(.menu)
                            }
                            .tint(Color.white)
                        }
                    }
                }
        }
        .navigationBarBackground(palette.accent)
        .navigationBarBackground(.visible)
        .navigationBarColorScheme(.dark)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    SMNavigationStack {
        Text("Hello!")
            .navigationTitle("Hello!")
    }
    .environmentObject(PaletteHolder())
}
