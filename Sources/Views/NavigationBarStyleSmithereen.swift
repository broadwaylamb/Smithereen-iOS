import SwiftUI

private struct NavigationBarStyleSmithereenModifier: ViewModifier {
    @EnvironmentObject private var palette: PaletteHolder

    func body(content: Content) -> some View {
        content
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackground(palette.accent)
            .navigationBarBackground(.visible)
            .navigationBarColorScheme(.dark)
    }
}

extension View {
    func navigationBarStyleSmithereen() -> some View {
        modifier(NavigationBarStyleSmithereenModifier())
    }
}
