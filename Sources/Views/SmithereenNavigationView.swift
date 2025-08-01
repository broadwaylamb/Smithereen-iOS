import SwiftUI

struct SmithereenNavigationView<Content: View>: View {
    @ViewBuilder var content: () -> Content

    @EnvironmentObject private var palette: PaletteHolder

    var body: some View {
        NavigationView {
            content()
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackground(palette.accent)
                .navigationBarBackground(.visible)
                .navigationBarColorScheme(.dark)
        }
        .navigationViewStyle(.stack)
        .navigationBarBackground(palette.accent)
        .navigationBarBackground(.visible)
        .navigationBarColorScheme(.dark)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    SmithereenNavigationView {
        Text("Hello!")
            .navigationTitle("Hello!")
    }
    .environmentObject(PaletteHolder())
}
