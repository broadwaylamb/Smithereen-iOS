import SwiftUI

@main
struct SmithereenApp: App {
    @StateObject private var api = RealAPIService()

    @StateObject private var paletteHolder = PaletteHolder()

    @ViewBuilder
    private var window: some View {
        // TODO: Animate the transitions
        switch api.state {
        case .loading:
            Color.white.ignoresSafeArea() // TODO: Show LaunchScreen
        case .authenticated(let actorStorage):
            RootView(api: api, actorStorage: actorStorage)
        case .notAuthenticated:
            AuthView(viewModel: AuthViewModel(api: api))
        }
    }

    var body: some Scene {
        WindowGroup {
            window
                .provideWebAuthenticationSession()
                .provideWindow()
                .tint(paletteHolder.accent)
                .overlay(alignment: .bottom) {
                    if false { // Flip to true if you want to experiment with colors
                        ColorSchemeCustomizer()
                    }
                }
                .environmentObject(paletteHolder)
                .task {
                    await api.loadAuthenticationState()
                }
        }
    }
}
