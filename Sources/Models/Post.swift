import Foundation
import SwiftSoup

struct PostHeader: Equatable {
    var localInstanceLink: URL
    var remoteInstanceLink: URL?
    var localAuthorID: URL
    var authorName: String
    var date: String
    var authorProfilePicture: ImageLocation?
}

struct Post: Identifiable, Equatable, Sendable {
    var header: PostHeader
    var text: PostText
    var likeCount: Int
    var replyCount: Int
    var repostCount: Int
    var liked: Bool
    var reposted: [Repost] = []

    var id: URL { header.localInstanceLink }
}

extension Post {
    init(
        id: URL,
        remoteInstanceLink: URL? = nil,
        localAuthorID: URL,
        authorName: String,
        date: String,
        authorProfilePicture: ImageLocation? = nil,
        text: PostText,
        likeCount: Int,
        replyCount: Int,
        repostCount: Int,
        liked: Bool,
        reposted: [Repost] = [],
    ) {
        header = PostHeader(
            localInstanceLink: id,
            remoteInstanceLink: remoteInstanceLink,
            localAuthorID: localAuthorID,
            authorName: authorName,
            date: date,
            authorProfilePicture: authorProfilePicture,
        )
        self.text = text
        self.likeCount = likeCount
        self.replyCount = replyCount
        self.repostCount = repostCount
        self.liked = liked
        self.reposted = reposted
    }
}

struct Repost: Identifiable, Equatable {
    var header: PostHeader
    var text: PostText
    var isMastodonStyleRepost: Bool

    var id: URL { header.localInstanceLink }
}

extension Repost {
    init(
        id: URL,
        remoteInstanceLink: URL? = nil,
        localAuthorID: URL,
        authorName: String,
        date: String,
        authorProfilePicture: ImageLocation? = nil,
        text: PostText,
        isMastodonStyleRepost: Bool,
    ) {
        header = PostHeader(
            localInstanceLink: id,
            remoteInstanceLink: remoteInstanceLink,
            localAuthorID: localAuthorID,
            authorName: authorName,
            date: date,
            authorProfilePicture: authorProfilePicture,
        )
        self.text = text
        self.isMastodonStyleRepost = isMastodonStyleRepost
    }
}
