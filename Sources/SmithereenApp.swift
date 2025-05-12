import SwiftUI
import SwiftData

@main
struct SmithereenApp: App {
    @ObservedObject var api = HTMLScrapingApi()

    var body: some Scene {
        WindowGroup {
            if api.isAuthenticated {
                RootView(feedService: api)
            } else {
                AuthView(api: api)
            }
        }
    }
}
