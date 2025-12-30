import SwiftUI
import SmithereenAPI

@MainActor
final class FeedViewModel: ObservableObject {
    private let api: APIService

    @Published private(set) var posts: [PostViewModel] = []

    init(api: APIService) {
        self.api = api
    }

    func update() async throws {
        let response = try await api.invokeMethod(
            Newsfeed.Get(
                filters: nil, // TODO: Filter
                startFrom: nil, // TODO: Pagination
                count: nil, // TODO: Pagination
                fields: nil, // TODO: Fields
            )
        )
        // TODO: Don't replace existing posts, mutate them instead.
        posts = response.items.compactMap { update in
            switch update.item {
            case .post(let post):
                PostViewModel(api: api, post: post, feed: self)
            default:
                nil
            }
        }
    }

    func addNewPost(_ post: WallPost) {
        let postViewModel = PostViewModel(api: api, post: post, feed: self)
        // TODO: Use deque?
        posts.insert(postViewModel, at: 0)
    }

    func createComposePostViewModel(
        errorObserver: ErrorObserver,
        isShown: Binding<Bool>,
    ) -> ComposePostViewModel {
        ComposePostViewModel(
            errorObserver: errorObserver,
            api: api,
            wallOwner: nil,
            isShown: isShown,
            showNewPost: self.addNewPost,
        )
    }
}
