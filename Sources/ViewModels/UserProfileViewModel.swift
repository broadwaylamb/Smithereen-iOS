import SwiftUI
import SmithereenAPI

@MainActor
@dynamicMemberLookup
final class UserProfileViewModel: ObservableObject {
    private let api: any APIService
    private let userHandle: String?
    private let feedViewModel: FeedViewModel
    @Published var user: UserProfile?
    @Published private var posts: [PostViewModel] = []
    @Published var wallMode: WallMode = .allPosts

    init(
        api: any APIService,
        userHandle: String?,
        feedViewModel: FeedViewModel,
    ) {
        self.api = api
        self.userHandle = userHandle
        self.feedViewModel = feedViewModel
    }

    subscript(dynamicMember keyPath: KeyPath<UserProfile, Int>) -> Int {
        user?[keyPath: keyPath] ?? 0
    }

    func update() async throws {
        guard let userHandle else { return }
        let request = UserProfileRequest(handle: userHandle)
        let result = try await api.send(request)
        withAnimation {
            user = result
            posts = result.posts.map {
                PostViewModel(api: api, post: $0, feed: feedViewModel)
            }
        }
    }

    var filteredPosts: [PostViewModel] {
        switch wallMode {
        case .allPosts:
            return posts
        case .ownPosts:
            return posts // TODO: Filter
        }
    }
}
