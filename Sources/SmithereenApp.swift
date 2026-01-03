import SwiftUI

@main
struct SmithereenApp: App {
    @StateObject private var api = RealAPIService()

    @StateObject private var paletteHolder = PaletteHolder()
    @StateObject private var feedViewModel: FeedViewModel

    init() {
        let api = RealAPIService()
        self._api = StateObject(wrappedValue: api)
        let viewModel = FeedViewModel(api: api)
        self._feedViewModel = StateObject(wrappedValue: viewModel)
    }

    @ViewBuilder
    private var window: some View {
        // TODO: Animate the transitions
        switch api.state {
        case .loading:
            Color.white // TODO: Show AuthView but without the inputs
        case .authenticated:
            RootView(api: api, feedViewModel: feedViewModel)
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
