import SwiftUI

struct SMNavigationStack<Content: View>: View {
    @Binding var path: NavigationPath
    @ViewBuilder var content: () -> Content

    @EnvironmentObject private var palette: PaletteHolder

    var body: some View {
        NavigationStack(path: $path) {
            content()
                .navigationBarStyleSmithereen()
                .environment(\.pushToNavigationStack) { item in
                    path.append(item)
                }
        }
        .navigationBarBackground(palette.accent)
        .navigationBarBackground(.visible)
        .navigationBarColorScheme(.dark)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    SMNavigationStack(path: .constant(.init())) {
        Text("Hello!")
            .navigationTitle("Hello!")
    }
    .environmentObject(PaletteHolder())
}
