import Foundation
import Hammond
import SwiftSoup

@POST("/users/{userID}/createWallPost")
@EncodableRequest
struct CreateWallPostRequest: DecodableRequestProtocol, RequiresCSRF {
    typealias ResponseBody = Data
    typealias Result = CreateWallPostResponse

    static let accept: ContentType = .application.json

    var text: String
    var userID: UserID
    var repost: PostID?

    private let replyTo: String = ""
    private let attachments: String = ""
    private let attachAltTexts: String = "{}"
    private let _ajax: Int = 1
}

struct CreateWallPostResponse: Decodable {
    var newPost: Post?
    init(from decoder: any Decoder) {
        var container = try? decoder.unkeyedContainer()
        struct Command: Decodable {
            var c: String
        }
        guard let html = try? container?.decodeIfPresent(Command.self)?.c else { return }
        guard let document = try? SwiftSoup.parse(html) else { return }
        newPost = try? FeedRequest.deserializeResult(from: document).posts.first
    }
}
