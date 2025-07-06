import SwiftUI

@main
struct SmithereenApp: App {
    private let api: HTMLScrapingApi

    @StateObject private var paletteHolder = PaletteHolder()
    @StateObject private var authenticationState: AuthenticationState
    @StateObject private var feedViewModel: FeedViewModel

    init() {
        let authenticationState = AuthenticationState()
        let api = HTMLScrapingApi(authenticationState: authenticationState)
        let feedViewModel = FeedViewModel(api: api)

        self.api = api
        self._authenticationState = StateObject(wrappedValue: authenticationState)
        self._feedViewModel = StateObject(wrappedValue: feedViewModel)
    }

    @ViewBuilder
    private var window: some View {
        // TODO: Animate the transitions
        if let authenticatedInstance = authenticationState.authenticatedInstance {
            RootView(api: api, feedViewModel: feedViewModel,)
                .environment(\.instanceURL, authenticatedInstance)
        } else {
            AuthView(api: api)
        }
    }

    var body: some Scene {
        WindowGroup {
            window
                .tint(paletteHolder.accent)
                .overlay(alignment: .bottom) {
                    if false { // Flip to true if you want to experiment with colors
                        ColorSchemeCustomizer()
                    }
                }
                .environmentObject(paletteHolder)
        }
    }
}

extension EnvironmentValues {
    @Entry var instanceURL: URL =
        URL(string: "http://smithereen.local")! // Stub, should not be used
}
