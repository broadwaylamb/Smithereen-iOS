import SwiftUI

enum PostKind: Equatable {
    case regular
    case repost(RepostInfo)

    func grayText(_ date: String) -> LocalizedStringKey {
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

    func grayText(_ date: String) -> LocalizedStringKey {
        switch self {
        case .post:
            "\(date)"
        case .comment(let inReplyTo):
            "\(date) on post \(inReplyTo)"
        case .commentToDeletedPost:
            "\(date) on a deleted post"
        }
    }
}

struct RepostInfo: Equatable {
    var isMastodonStyle: Bool
    var entity: RepostedEntity
}
