import SwiftUI
import SwiftData

@main
struct SmithereenApp: App {
    @StateObject private var api: HTMLScrapingApi
    @StateObject private var feedViewModel: FeedViewModel

    init() {
        let api = HTMLScrapingApi()
        self._api = StateObject(wrappedValue: api)
        self._feedViewModel = StateObject(wrappedValue: FeedViewModel(api: api))
    }

    var body: some Scene {
        WindowGroup {
            if api.isAuthenticated {
                RootView(feedViewModel: FeedViewModel(api: api))
            } else {
                AuthView(api: api)
            }
        }
    }
}
