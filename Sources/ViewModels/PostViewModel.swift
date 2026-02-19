import GRDB
import SwiftUI
import SmithereenAPI

@MainActor
final class PostViewModel: ObservableObject, Identifiable {
    let id: WallPostID
    let api: any APIService
    let db: SmithereenDatabase
    @Published private(set) var post: WallPost

    @Published private(set) var commentCount: Int = 0
    @Published var repostCount: Int = 0
    @Published var likeCount: Int = 0
    @Published private(set) var liked: Bool = false
    @Published var reposted = false
    @Published private var authors: [UserID : User] = [:]

    // periphery:ignore
    private var authorsObservation: AnyDatabaseCancellable?

    init(
        api: any APIService,
        db: SmithereenDatabase,
        post: WallPost,
        profiles: [User],
    ) {
        self.id = post.id
        self.api = api
        self.db = db
        self.post = post
        update(from: post, profiles: profiles)
    }

    private func observeAuthors(_ post: WallPost) {
        authorsObservation = db.observe { db in
            try User.fetchAll(db, ids: post.authorIDs)
        } onChange: { [unowned self] in
            self.setAuthors($0)
        }
    }

    private func setAuthors(_ newAuthors: [User]) {
        var newAuthorsDict = [UserID : User]()
        newAuthorsDict.reserveCapacity(newAuthors.count)
        for newAuthor in newAuthors {
            newAuthorsDict[newAuthor.id] = newAuthor
        }
        authors = newAuthorsDict
    }

    func update(from post: WallPost, profiles: [User]) {
        self.post = post
        commentCount = post.postForInteractions.comments?.count ?? 0
        repostCount = post.postForInteractions.reposts?.count ?? 0
        reposted = post.postForInteractions.reposts?.userReposted ?? false
        likeCount = post.postForInteractions.likes?.count ?? 0
        liked = post.postForInteractions.likes?.userLikes ?? false
        let authorIDs = post.authorIDs
        setAuthors(profiles.filter { authorIDs.contains($0.id) })
        observeAuthors(post)
    }

    var originalPostURL: URL {
        post.postForInteractions.url
    }

    var isOwnPost: Bool {
        post.fromID.userID == db.currentUserID
    }

    var canComment: Bool {
        post.postForInteractions.comments?.canComment ?? false
    }

    var displayCommentButton: Bool {
        canComment || (post.postForInteractions.comments?.count ?? 0) > 0
    }

    var canRepost: Bool {
        post.postForInteractions.likes?.canLike ?? false
    }

    var displayRepostButton: Bool {
        canRepost || (post.postForInteractions.reposts?.count ?? 0) > 0
    }

    var canLike: Bool {
        post.postForInteractions.likes?.canLike ?? false
    }

    var displayLikeButton: Bool {
        canLike || (post.postForInteractions.likes?.count ?? 0) > 0
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
        if let user = authors[authorID] {
            return user.toPostAuthor()
        }

        // This can only happen if the server doesn't send us the correct array
        // of users in the response.
        fetchAuthorsTask = Task {
            let request = Users.Get(
                userIDs: post.authorIDs,
                fields: ActorStorage.userFields,
            )
            let users = try await api.invokeMethod(request)
            setAuthors(users)
        }

        return PostAuthor(
            id: ActorID(authorID),
            displayedName: "…",
            profilePictureSizes: ImageSizes(),
        )
    }

    private var fetchAuthorsTask: Task<Void, any Error>?

    deinit {
        fetchAuthorsTask?.cancel()
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
            let gender = post.fromID.userID.flatMap { authors[$0] }?.sex
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

    var authorIDs: [UserID] {
        var r = [UserID]()
        r.reserveCapacity(1 + (repostHistory?.count ?? 0))
        if let userID = fromID.userID {
            r.append(userID)
        }
        for repost in repostHistory ?? [] {
            if let userID = repost.fromID.userID {
                r.append(userID)
            }
        }
        return r.distinct()
    }
}

extension User {
    func toPostAuthor() -> PostAuthor {
        PostAuthor(
            id: ActorID(id),
            displayedName: nameComponents.formatted(.name(style: .medium)),
            profilePictureSizes: squareProfilePictureSizes,
        )
    }

    var squareProfilePictureSizes: ImageSizes {
        var sizes = ImageSizes()
        sizes.append(size: 50, url: photo50)
        sizes.append(size: 100, url: photo100)
        sizes.append(size: 200, url: photo200)
        sizes.append(size: 400, url: photo400)
        sizes.append(size: .infinity, url: photoMax)
        return sizes
    }
}
