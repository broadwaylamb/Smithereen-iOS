import Foundation
import SmithereenAPI
import SwiftSoup

struct PostHeader: Equatable {
    var id: WallPostID
    var localURL: URL
    var remoteInstanceLink: URL?
    var authorHandle: String
    var authorName: String
    var date: String
    var authorProfilePicture: ImageLocation?
}

struct Post: Equatable, Sendable {
    var header: PostHeader
    var text: PostText
    var likeCount: Int
    var replyCount: Int
    var repostCount: Int
    var liked: Bool
    var reposted: [Repost] = []
    var attachments: [PostAttachment] = []
}

extension Post {
    init(
        id: WallPostID,
        localURL: URL,
        remoteInstanceLink: URL? = nil,
        authorHandle: String,
        authorName: String,
        date: String,
        authorProfilePicture: ImageLocation? = nil,
        text: PostText,
        likeCount: Int,
        replyCount: Int,
        repostCount: Int,
        liked: Bool,
        attachments: [PostAttachment] = [],
        reposted: [Repost] = [],
    ) {
        header = PostHeader(
            id: id,
            localURL: localURL,
            remoteInstanceLink: remoteInstanceLink,
            authorHandle: authorHandle,
            authorName: authorName,
            date: date,
            authorProfilePicture: authorProfilePicture,
        )
        self.text = text
        self.likeCount = likeCount
        self.replyCount = replyCount
        self.repostCount = repostCount
        self.liked = liked
        self.attachments = attachments
        self.reposted = reposted
    }
}

struct Repost: Identifiable, Equatable {
    var header: PostHeader
    var text: PostText
    var isMastodonStyleRepost: Bool
    var attachments: [PostAttachment] = []

    var id: WallPostID { header.id }

    var hasContent: Bool {
        !text.isEmpty && !attachments.isEmpty
    }
}
