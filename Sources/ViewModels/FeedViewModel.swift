import SwiftUI

@MainActor
final class FeedViewModel: ObservableObject {
    private let api: APIService
    @Published private(set) var posts: [PostViewModel] = []

    init(api: APIService) {
        self.api = api
    }

    func update() async throws {
        let newPosts = try await api.send(FeedRequest())
        // TODO: Don't replace existing posts, mutate them instead.
        posts = newPosts.map { PostViewModel(api: api, post: $0) }
    }
}
