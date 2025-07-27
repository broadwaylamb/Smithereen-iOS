import Foundation
import Hammond

@GET("/posts/{postID}/like")
@EncodableRequest
struct LikeRequest: DecodableRequestProtocol, RequiresCSRF {
    typealias ResponseBody = Data
    typealias Result = LikeResponse

    static let accept: ContentType = .application.json

    var postID: PostID
    @Query(key: "_ajax") private let ajax: Int = 1
}

@GET("/posts/{postID}/unlike")
@EncodableRequest
struct UnlikeRequest: DecodableRequestProtocol, RequiresCSRF {
    typealias ResponseBody = Data
    typealias Result = LikeResponse

    static let accept: ContentType = .application.json

    var postID: PostID
    @Query(key: "_ajax") private let ajax: Int = 1
}

struct LikeResponse: Decodable {
    var newLikeCount: Int?

    init(from decoder: any Decoder) throws {
        var container = try decoder.unkeyedContainer()
        struct Command: Decodable {
            var c: String
        }
        let command = try container.decodeIfPresent(Command.self)
        newLikeCount = command.flatMap { Int($0.c) }
    }
}
