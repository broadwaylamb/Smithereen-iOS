import Foundation
import SmithereenAPI
import SwiftSoup

struct PostHeader: Equatable {
    var id: WallPostID
}

struct Post: Equatable, Sendable {}

struct Repost: Equatable {
    var text: PostText
    var attachments: [PostAttachment] = []
}
