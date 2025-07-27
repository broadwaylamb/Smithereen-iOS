import SwiftUI

@MainActor
final class FeedViewModel: ObservableObject {
    private let api: FeedService
    @Published private(set) var posts: [PostViewModel] = []

    init(api: FeedService) {
        self.api = api
    }

    func update() async throws {
        let newPosts = try await api.loadFeed()
        // TODO: Don't replace existing posts, mutate them instead.
        posts = newPosts.map(PostViewModel.init)
    }
}
