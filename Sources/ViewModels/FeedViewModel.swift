import SwiftUI
import SmithereenAPI

@MainActor
final class FeedViewModel: ObservableObject {
    private let api: APIService
    private let actorStorage: ActorStorage

    @Published private(set) var posts: [PostViewModel] = []

    init(api: APIService, actorStorage: ActorStorage) {
        self.api = api
        self.actorStorage = actorStorage
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
        let userViewModels = actorStorage.cacheUsers(response.profiles)

        // TODO: Don't replace existing posts, mutate them instead.
        posts = response.items.compactMap { update in
            switch update.item {
            case .post(let postUpdate):
                // TODO: Respect postUpdate.matchedFilters
                PostViewModel(
                    api: api,
                    actorStorage: actorStorage,
                    authors: userViewModels,
                    post: postUpdate.post,
                )
            default:
                nil
            }
        }
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
        )
    }
}
