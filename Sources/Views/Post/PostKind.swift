import SwiftUI

enum PostKind: Equatable {
    case regular
    case repost(isMastodonStyle: Bool)
    case commentRepost(inReplyTo: String, isMastodonStyle: Bool)
    case commentToDeletedPostRepost(isMastodonStyle: Bool)

    func grayText(_ date: String) -> LocalizedStringKey {
        switch self {
        case .regular, .repost:
            "\(date)"
        case .commentRepost(let inReplyTo, _):
            "\(date) on post \(inReplyTo)"
        case .commentToDeletedPostRepost:
            "\(date) on a deleted post"
        }
    }
}
