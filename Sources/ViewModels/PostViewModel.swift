import SwiftUI

final class PostViewModel: ObservableObject {
    private var post: Post

    @Published var commentCount: Int = 0
    @Published var repostCount: Int = 0
    @Published var likeCount: Int = 0
    @Published var liked: Bool = false

    @MainActor
    init(post: Post) {
        self.post = post
        update(from: post)
    }

    @MainActor
    func update(from post: Post) {
        self.post = post
        commentCount = post.replyCount
        repostCount = post.repostCount
        likeCount = post.likeCount
        liked = post.liked
    }

    var originalPostURL: URL {
        // TODO
        fatalError()
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
}

extension PostViewModel: Identifiable {
    var id: PostID {
        post.header.id
    }
}
