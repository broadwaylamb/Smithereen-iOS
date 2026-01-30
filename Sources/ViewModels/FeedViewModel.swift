import SwiftUI
import SmithereenAPI

@MainActor
final class FeedViewModel: ObservableObject {
    private let api: APIService
    private let db: SmithereenDatabase

    @Published private(set) var posts: [PostViewModel] = []

    init(api: APIService, db: SmithereenDatabase) {
        self.api = api
        self.db = db
    }

    func update(errorObserver: ErrorObserver) async throws {
        let response = try await api.invokeMethod(
            Newsfeed.Get(
                filters: nil, // TODO: Filter
                startFrom: nil, // TODO: Pagination
                count: nil, // TODO: Pagination
                fields: ActorStorage.actorFields,
            )
        )
        try db.cacheUsers(response.profiles)

        // TODO: Don't replace existing posts, mutate them instead.
        posts = response.items.compactMap { update in
            switch update.item {
            case .post(let postUpdate):
                // TODO: Respect postUpdate.matchedFilters
                PostViewModel(
                    api: api,
                    db: db,
                    post: postUpdate.post,
                    profiles: response.profiles,
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
