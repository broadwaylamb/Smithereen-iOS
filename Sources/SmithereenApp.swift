import SwiftUI
import SwiftData

@main
struct SmithereenApp: App {
    private let api: HTMLScrapingApi

    @StateObject private var paletteState: PaletteState = PaletteState()
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
        if authenticationState.isAuthenticated {
            RootView(feedViewModel: feedViewModel)
        } else {
            AuthView(api: api)
        }
    }

    var body: some Scene {
        WindowGroup {
            window
                .tint(paletteState.palette.accent)
                .environmentObject(paletteState)
                .environment(\.palette, paletteState.palette)
        }
    }
}
