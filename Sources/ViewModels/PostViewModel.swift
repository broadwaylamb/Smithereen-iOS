import SwiftUI
import SmithereenAPI

@MainActor
final class PostViewModel: ObservableObject, Identifiable {
    let id: WallPostID
    let api: any APIService
    let actorStorage: ActorStorage
    let authors: [UserID : UserProfileViewModel]
    @Published var post: WallPost

    @Published var commentCount: Int = 0
    @Published var repostCount: Int = 0
    @Published var likeCount: Int = 0
    @Published var liked: Bool = false
    @Published var reposted = false

    init(
        api: any APIService,
        actorStorage: ActorStorage,
        authors: [UserID : UserProfileViewModel],
        post: WallPost,
    ) {
        self.id = post.id
        self.api = api
        self.actorStorage = actorStorage
        self.authors = authors
        self.post = post
        update(from: post)
    }

    func update(from post: WallPost) {
        self.post = post
        commentCount = post.postForInteractions.comments?.count ?? 0
        repostCount = post.postForInteractions.reposts?.count ?? 0
        reposted = post.postForInteractions.reposts?.userReposted ?? false
        likeCount = post.postForInteractions.likes?.count ?? 0
        liked = post.postForInteractions.likes?.userLikes ?? false
    }

    var originalPostURL: URL {
        post.url
    }

    var isOwnPost: Bool {
        post.fromID.userID == actorStorage.currentUserID
    }

    var canComment: Bool {
        post.comments?.canComment ?? false
    }

    var displayCommentButton: Bool {
        canComment || (post.comments?.count ?? 0) > 0
    }

    var canRepost: Bool {
        post.likes?.canLike ?? false
    }

    var displayRepostButton: Bool {
        canRepost || (post.reposts?.count ?? 0) > 0
    }

    var canLike: Bool {
        post.likes?.canLike ?? false
    }

    var displayLikeButton: Bool {
        canLike || (post.likes?.count ?? 0) > 0
    }

    var repostIDs: [WallPostID] {
        post.repostHistory?.map(\.id) ?? []
    }

    func hasContent(postID: WallPostID? = nil) -> Bool {
        let post = getPostIncludingReposted(postID)
        let hasText = !(post.text?.isEmpty ?? true)
        let hasAttachments = !(post.attachments?.isEmpty ?? true)
        return hasText || hasAttachments
    }

    var isMastodonStyleRepost: Bool {
        post.isMastodonStyleRepost ?? false
    }

    /// Returns the author of the post or of one of the reposted posts.
    ///
    /// - parameter id: If this is a repost, the identifier of a reposted post.
    ///   If `nil`, returns the author of the post itself.
    func getAuthor(_ id: WallPostID? = nil) -> PostAuthor {
        let post = getPostIncludingReposted(id)
        guard let authorID = post.fromID.userID else {
            // TODO: Support posts from groups
            fatalError("Posts from groups are not supported")
        }
        if let viewModel = authors[authorID] {
            return viewModel.toPostAuthor()
        }

        // This can only happen if the server doesn't send us the correct array
        // of users in the response.
        return actorStorage.getUser(authorID).toPostAuthor()
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
        let post = getPostIncludingReposted(postID)
        let formattedDate = AdaptiveDateFormatter.default.string(from: post.date)
        switch post.postSource?.action {
        case .profilePictureUpdate:
            let gender = post.fromID.userID.flatMap { authors[$0] }?.user?.sex
            switch gender {
            case .female:
                return String(localized: "updated her profile picture \(formattedDate)")
            case .male:
                return String(localized: "updated his profile picture \(formattedDate)")
            case .other, nil:
                return String(localized: "updated their profile picture \(formattedDate)")
            }
        case nil:
            return formattedDate
        }
    }

    func getText(postID: WallPostID? = nil) -> RichText {
        // TODO: Cache parsed HTML?
        getPostIncludingReposted(postID)
            .text
            .map(RichText.init(html:))
            ?? RichText()
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
        )
    }

    private func withLikeAnimation(_ body: () -> Void) {
        withAnimation(.easeInOut(duration: 0.2), body)
    }
}

extension WallPost {
    var postForInteractions: WallPost {
        if isMastodonStyleRepost == true {
            return repostHistory?.first ?? self
        } else {
            return self
        }
    }
}
