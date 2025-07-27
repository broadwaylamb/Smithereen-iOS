import SwiftUI

@MainActor
final class FeedViewModel: ObservableObject {
    private let api: APIService

    @Published private var currentUserID: UserID?
    @Published private(set) var posts: [PostViewModel] = []

    init(api: APIService) {
        self.api = api
    }

    func update() async throws {
        let response = try await api.send(FeedRequest())
        // TODO: Don't replace existing posts, mutate them instead.
        posts = response.posts.map { PostViewModel(api: api, post: $0) }

        currentUserID = response.currentUserID
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
        ) { newPost in
            self.posts.insert(PostViewModel(api: self.api, post: newPost), at: 0)
        }
    }
}
