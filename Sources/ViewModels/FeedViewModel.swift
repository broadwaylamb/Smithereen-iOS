import SwiftUI
import SmithereenAPI

@MainActor
final class FeedViewModel: ObservableObject {
    private let api: APIService

    @Published private(set) var currentUserID: UserID?
    @Published private(set) var currentUserHandle: String?
    @Published private(set) var posts: [PostViewModel] = []

    init(api: APIService) {
        self.api = api
    }

    func update() async throws {
        let response = try await api.send(FeedRequest())
        // TODO: Don't replace existing posts, mutate them instead.
        posts = response.posts.map {
            PostViewModel(api: api, post: $0, feed: self)
        }

        currentUserID = response.currentUserID
        currentUserHandle = response.currentUserHandle
    }

    func addNewPost(_ post: Post) {
        let postViewModel = PostViewModel(api: api, post: post, feed: self)
        // TODO: Use deque?
        posts.insert(postViewModel, at: 0)
    }

    var canComposePost: Bool {
        currentUserID != nil
    }

    func createComposePostViewModel(
        errorObserver: ErrorObserver,
        isShown: Binding<Bool>,
    ) -> ComposePostViewModel {
        ComposePostViewModel(
            errorObserver: errorObserver,
            api: api,
            userID: currentUserID,
            isShown: isShown,
            showNewPost: self.addNewPost,
        )
    }
}
