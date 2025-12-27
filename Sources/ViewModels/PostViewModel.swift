import SwiftUI
import SmithereenAPI

@MainActor
final class PostViewModel: ObservableObject, Identifiable {
    let id: WallPostID
    let api: any APIService
    private var post: Post

    // Needed so that we could push a repost of this post to it, thus updating the feed immediately
    private weak var feedViewModel: FeedViewModel?

    @Published var commentCount: Int = 0
    @Published var repostCount: Int = 0
    @Published var likeCount: Int = 0
    @Published var liked: Bool = false

    init(api: any APIService, post: Post, feed: FeedViewModel) {
        self.id = post.header.id
        self.api = api
        self.post = post
        self.feedViewModel = feed
        update(from: post)
    }

    func update(from post: Post) {
        self.post = post
        commentCount = post.replyCount
        repostCount = post.repostCount
        likeCount = post.likeCount
        liked = post.liked
    }

    var originalPostURL: URL {
        post.header.remoteInstanceLink ?? post.header.localURL
    }

    var header: PostHeader {
        post.header
    }

    var text: PostText {
        post.text
    }

    var attachments: [PostAttachment] {
        post.attachments
    }

    var reposted: [Repost] {
        post.reposted
    }

    var hasContent: Bool {
        !text.isEmpty && !attachments.isEmpty
    }

    func like() {
        let previousLikeCount = likeCount
        let previousState = liked
        withLikeAnimation {
            liked.toggle()
            if liked {
                likeCount += 1
            } else {
                likeCount -= 1
            }
        }

        Task {
            do {
                let response = if liked {
                    try await api.send(LikeRequest(postID: post.header.id))
                } else {
                    try await api.send(UnlikeRequest(postID: post.header.id))
                }
                if let newLikeCount = response.newLikeCount, newLikeCount != likeCount {
                    withLikeAnimation {
                        likeCount = newLikeCount
                    }
                }
            } catch {
                // Don't bombard the user with error messages if there was an error,
                // just silently reset to the previous state.
                withLikeAnimation {
                    liked = previousState
                    likeCount = previousLikeCount
                }
            }
        }
    }

    func createComposeRepostViewModel(
        isShown: Binding<Bool>,
        errorObserver: ErrorObserver,
    ) -> ComposePostViewModel {
        ComposePostViewModel(
            errorObserver: errorObserver,
            api: api,
            userID: feedViewModel?.currentUserID,
            isShown: isShown,
            repostedPost: self,
            showNewPost: { self.feedViewModel?.addNewPost($0) }
        )
    }

    private func withLikeAnimation(_ body: () -> Void) {
        withAnimation(.easeInOut(duration: 0.2), body)
    }
}
