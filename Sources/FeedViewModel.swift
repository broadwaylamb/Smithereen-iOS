import SwiftUI

@MainActor
class FeedViewModel: ObservableObject {
    private let api: FeedService
    @Published private(set) var posts: [Post]

    init(api: FeedService, posts: [Post] = []) {
        self.api = api
        self.posts = posts
    }

    func update() async throws {
        posts = try await api.loadFeed()
    }
}
