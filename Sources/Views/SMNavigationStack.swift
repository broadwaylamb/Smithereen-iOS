import SwiftUI
import SlideableMenu

struct SMNavigationStack<Content: View>: View {
    var isModal = false
    @ViewBuilder var content: () -> Content

    @State var path = NavigationPath()
    @EnvironmentObject private var palette: PaletteHolder

    @Environment(\.isSlideableMenuFixed) private var isSlideableMenuFixed
    @Environment(\.revealSlideableMenu) private var revealSlideableMenu
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack(path: $path) {
            content()
                .navigationBarStyleSmithereen()
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        if !isSlideableMenuFixed && !isModal {
                            Button(action: revealSlideableMenu.callAsFunction) {
                                Image(.menu)
                            }
                            .tint(Color.white)
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        if isModal {
                            Button(action: dismiss.callAsFunction) {
                                Image(.close)
                            }
                            .tint(Color.white)
                        }
                    }
                }
        }
        .environment(\.pushToNavigationStack) { item in
            path.append(item)
        }
        .navigationBarBackground(palette.accent)
        .navigationBarBackground(.visible)
        .navigationBarColorScheme(.dark)
        .preferredColorScheme(.dark)
        .accentColor(.white)
    }
}

extension EnvironmentValues {
    @Entry var pushToNavigationStack: (any Hashable) -> Void = { _ in }
}

#Preview {
    SMNavigationStack {
        Text("Hello!")
            .navigationTitle("Hello!")
    }
    .environmentObject(PaletteHolder())
}
