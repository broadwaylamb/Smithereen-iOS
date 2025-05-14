import Foundation

struct Post: Identifiable, Equatable {
    var id: URL
    var remoteInstanceLink: URL?
    var localAuthorID: URL
    var authorName: String
    var date: String // String because we're getting it directly from HTML
    var authorProfilePicture: ImageLocation?
    var text: AttributedString?
    var likeCount: Int
    var replyCount: Int
    var repostCount: Int
    var reposted: Box<Post>?
}
