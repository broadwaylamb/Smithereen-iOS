import SwiftUI

@MainActor
@dynamicMemberLookup
final class UserProfileViewModel: ObservableObject {
    private let api: any APIService
    private let userIDOrHandle: Either<UserID, String>?
    private let feedViewModel: FeedViewModel
    @Published var user: UserProfile?
    @Published var posts: [PostViewModel] = []

    init(
        api: any APIService,
        userIDOrHandle: Either<UserID, String>?,
        feedViewModel: FeedViewModel,
    ) {
        self.api = api
        self.userIDOrHandle = userIDOrHandle
        self.feedViewModel = feedViewModel
    }

    subscript(dynamicMember keyPath: KeyPath<UserProfile, Int>) -> Int {
        user?[keyPath: keyPath] ?? 0
    }

    func update() async throws {
        let request: UserProfileRequest
        switch userIDOrHandle {
        case .left(let userID)?:
            request = UserProfileRequest(userID: userID)
        case .right(let handle)?:
            request = UserProfileRequest(handle: handle)
        case nil:
            return
        }
        let result = try await api.send(request)
        withAnimation {
            user = result
            posts = result.posts.map {
                PostViewModel(api: api, post: $0, feed: feedViewModel)
            }
        }
    }
}
