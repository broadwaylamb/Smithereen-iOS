import SwiftUI
import SwiftData

@main
struct SmithereenApp: App {
    private let api: HTMLScrapingApi
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

    var body: some Scene {
        WindowGroup {
            if authenticationState.isAuthenticated {
                RootView(feedViewModel: feedViewModel)
            } else {
                AuthView(api: api)
            }
        }
    }
}
