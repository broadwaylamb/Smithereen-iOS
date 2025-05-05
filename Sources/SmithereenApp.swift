import SwiftUI
import SwiftData

@main
struct SmithereenApp: App {
    @StateObject private var api = HTMLScrapingAuthenticationService()

    var body: some Scene {
        WindowGroup {
            if api.isAuthenticated {
                RootView()
            } else {
                AuthView(api: api)
            }
        }
    }
}
