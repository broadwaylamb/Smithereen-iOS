import SwiftUI
import SmithereenAPI

@MainActor
final class PostViewModel: ObservableObject, Identifiable {
    let id: WallPostID
    let api: any APIService
    private(set) var post: WallPost

    // Needed so that we could push a repost of this post to it, thus updating the feed immediately
    private weak var feedViewModel: FeedViewModel?

    @Published var commentCount: Int = 0
    @Published var repostCount: Int = 0
    @Published var likeCount: Int = 0
    @Published var liked: Bool = false

    init(api: any APIService, post: WallPost, feed: FeedViewModel) {
        self.id = post.id
        self.api = api
        self.post = post
        self.feedViewModel = feed
        update(from: post)
    }

    @available(*, deprecated)
    convenience init(api: any APIService, post: Post, feed: FeedViewModel) {
        fatalError("To be removed")
    }

    func update(from post: WallPost) {
        self.post = post
        commentCount = post.comments?.count ?? 0
        repostCount = post.reposts?.count ?? 0
        likeCount = post.likes?.count ?? 0
        liked = post.likes?.userLikes ?? false
    }

    var originalPostURL: URL {
        post.url
    }

    var repostIDs: [WallPostID] {
        post.repostHistory?.map(\.id) ?? []
    }

    func hasContent(postID: WallPostID? = nil) -> Bool {
        let post = getPostIncludingReposted(postID)
        return !(post.text?.isEmpty ?? true) && !(post.attachments ?? []).isEmpty
    }

    var isMastodonStyleRepost: Bool {
        post.isMastodonStyleRepost ?? false
    }

    func getAuthor(_ id: WallPostID? = nil) -> PostAuthor {
        fatalError("Not implemented yet")
    }

    private func getPostIncludingReposted(_ postID: WallPostID?) -> WallPost {
        guard let postID = postID else {
            return post
        }
        if postID == post.id {
           return post
        } else {
            for repost in self.post.repostHistory ?? [] {
                if postID == repost.id {
                    return repost
                }
            }
        }
        fatalError("Post with ID \(postID) not found among reposts of \(id)")
    }

    func getPostDate(postID: WallPostID? = nil) -> String {
        postDateFormatter.string(from: getPostIncludingReposted(postID).date)
    }

    func getText(postID: WallPostID? = nil) -> PostText {
        // TODO: Cache parsed HTML?
        getPostIncludingReposted(postID)
            .text
            .map(PostText.init(html:))
            ?? PostText()
    }

    func getAttachments(postID: WallPostID? = nil) -> [Attachment] {
        getPostIncludingReposted(postID).attachments ?? []
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
                let newLikeCount = if liked {
                    try await api.invokeMethod(Likes.Add(itemID: .post(id))).likes
                } else {
                    try await api.invokeMethod(Likes.Delete(itemID: .post(id))).likes
                }
                if newLikeCount != likeCount {
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
            wallOwner: nil,
            isShown: isShown,
            repostedPost: self,
            showNewPost: { self.feedViewModel?.addNewPost($0) }
        )
    }

    private func withLikeAnimation(_ body: () -> Void) {
        withAnimation(.easeInOut(duration: 0.2), body)
    }
}

private let postDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.doesRelativeDateFormatting = true
    formatter.dateStyle = .long
    formatter.timeStyle = .short
    return formatter
}()
