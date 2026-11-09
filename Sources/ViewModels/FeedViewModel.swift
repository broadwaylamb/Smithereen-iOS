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

    nonisolated func update(
        textRenderingParameters: TextRenderingParameters
    ) async throws {
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
        let newPosts = response.items.compactMap { update in
            switch update.item {
            case .post(let postUpdate):
                // TODO: Respect postUpdate.matchedFilters
                (postUpdate.post,
                 PostViewModel.prerenderTexts(
                    post: postUpdate.post,
                    parameters: textRenderingParameters,
                 )
                )
            case .photo(_):
                nil // TODO
            case .photoTag(_):
                nil // TODO
            case .friend(_):
                nil // TODO
            case .groupJoin(_):
                nil // TODO
            case .groupCreate(_):
                nil // TODO
            case .eventJoin(_):
                nil // TODO
            case .eventCreate(_):
                nil // TODO
            case .board(_):
                nil // TODO
            case .relation(_):
                nil // TODO
            }
        }

        await MainActor.run {
            posts = newPosts.map { (post, renderedTexts) in
                PostViewModel(
                    api: api,
                    db: db,
                    post: post,
                    profiles: response.profiles,
                    renderedTexts: renderedTexts
                )
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
