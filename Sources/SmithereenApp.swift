import SwiftUI

@main
struct SmithereenApp: App {
    @StateObject private var api = RealAPIService()

    @StateObject private var paletteHolder = PaletteHolder()

    @ViewBuilder
    private var window: some View {
        switch api.state {
        case .loading:
            Color.white.ignoresSafeArea() // TODO: Show LaunchScreen
        case .authenticated(let db):
            RootView(api: api, db: db)
                .captchaPrompt($api.captchaPrompt)
        case .notAuthenticated:
            AuthView(viewModel: AuthViewModel(api: api))
        }
    }

    private struct AnimatableAuthenticationState: Equatable {
        var state: AuthenticationState

        static func == (lhs: Self, rhs: Self) -> Bool {
            switch (lhs.state, rhs.state) {
            case (.loading, .loading): return true
            case (.authenticated, .authenticated): return true
            case (.notAuthenticated, .notAuthenticated): return true
            default: return false
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            window
                .animation(
                    .easeIn(duration: 0.15),
                    value: AnimatableAuthenticationState(state: api.state)
                )
                .provideWebAuthenticationSession()
                .provideWindow()
                .tint(paletteHolder.accent)
                .environmentObject(paletteHolder)
                .task {
                    await api.loadAuthenticationState()
                }
        }
    }
}
