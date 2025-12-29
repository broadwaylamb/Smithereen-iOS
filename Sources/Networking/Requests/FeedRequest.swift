import Foundation
import Hammond
import HammondMacros
import SwiftSoup
import SmithereenAPI

@GET("/feed")
@EncodableRequest
struct FeedRequest: DecodableRequestProtocol {
    @Query var start: Int?
    @Query var offset: Int?

    func deserializeResult(from document: Document) throws -> FeedResponse {
        let createWallPostURL = try document
            .select("#wallPostFormForm_feed")
            .first()?
            .attr("action")

        let userID = createWallPostURL
            .flatMap {
                userIDRegex.firstMatch(in: $0, captureGroup: 1)
            }
            .flatMap { UInt32($0) }
            .map(UserID.init)
            ?? UserID(rawValue: 0)

        let userHandle = try document.select("#myProfileLink").attr("href").dropFirst()

        return FeedResponse(
            posts: [],
            currentUserID: userID,
            currentUserHandle: String(userHandle),
        )
    }
}

struct FeedResponse {
    var posts: [Post]
    var currentUserID: UserID
    var currentUserHandle: String
}

private let userIDRegex =
    try! NSRegularExpression(pattern: "/users/([0-9]+)/createWallPost")
