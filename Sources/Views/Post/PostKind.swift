import SwiftUI
import SmithereenAPI

enum PostKind: Equatable {
    case regular
    case repost(RepostInfo)

    func grayText(_ date: String) -> String {
        switch self {
        case .regular:
            "\(date)"
        case .repost(let repostInfo):
            repostInfo.entity.grayText(date)
        }
    }
}

enum RepostedEntity: Equatable {
    case post
    case comment(inReplyTo: String)
    case commentToDeletedPost

    func grayText(_ date: String) -> String {
        switch self {
        case .post:
            String(localized: "\(date)")
        case .comment(let inReplyTo):
            String(localized: "\(date) on post \(inReplyTo)")
        case .commentToDeletedPost:
            String(localized: "\(date) on a deleted post")
        }
    }
}

struct RepostInfo: Equatable {
    /// The nestedness of the repost. The top-level repost has level 0.
    var level: Int
    var isMastodonStyle: Bool
    var repostedPostID: WallPostID
    var entity: RepostedEntity
}
