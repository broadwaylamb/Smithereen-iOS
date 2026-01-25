import Foundation
import SmithereenAPI

struct RepostWithCounters: Codable {
    var postID: WallPostID
    var repostsCount: Int
    var likesCount: Int

    private enum CodingKeys: String, CodingKey {
        case postID = "post_id"
        case repostsCount = "reposts_count"
        case likesCount = "likes_count"
    }
}

extension Execute<Wall.Repost, RepostWithCounters> {
    private static let script = scriptResource("repostWithCounters")

    static func repostWithCounters(
        postID: WallPostID,
        message: String? = nil,
        textFormat: TextFormat? = nil,
        attachments: [AttachmentToCreate]? = nil,
        contentWarning: String? = nil,
        guid: UUID? = nil,
    ) -> Self {
        Execute(
            code: script,
            args: Wall.Repost(
                postID: postID,
                message: message,
                textFormat: textFormat,
                attachments: attachments,
                contentWarning: contentWarning,
                guid: guid,
            )
        )
    }
}
