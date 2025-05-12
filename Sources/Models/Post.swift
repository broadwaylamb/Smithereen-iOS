import Foundation

struct Post: Identifiable {
    var id: URL
    var remoteInstanceLink: URL?
    var localAuthorID: URL
    var authorName: String
    var date: String // String because we're getting it directly from HTML
    var authorProfilePictureURL: URL?
    var text: String?
    var likeCount: Int
    var replyCount: Int
    var repostCount: Int
    var reposted: Box<Post>?
}
