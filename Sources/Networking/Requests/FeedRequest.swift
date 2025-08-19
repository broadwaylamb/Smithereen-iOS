import Foundation
import Hammond
import SwiftSoup

@GET("/feed")
@EncodableRequest
struct FeedRequest: DecodableRequestProtocol {
    @Query var start: Int?
    @Query var offset: Int?

    private static func parseSinglePost(
        _ container: Element,
        authorNameLinkSelector: String,
        postLinkSelector: String,
    ) throws -> PostHeader? {
        guard let authorNameLink = try container.select(authorNameLinkSelector).first(),
              let authorURL = try URL(string: authorNameLink.attr("href"))
        else {
            return nil
        }

        let authorName = try authorNameLink.text(trimAndNormaliseWhitespace: true)

        guard let postLink = try container.select(postLinkSelector).first(),
              let localPostURL = (try? postLink.attr("href")).flatMap(URL.init(string:)),
              let postID = localPostURL
                  .absoluteString
                  .components(separatedBy: "posts/")
                  .last
                  .flatMap(Int.init)
                  .map(PostID.init)
        else {
            return nil
        }
        let date = try postLink.text(trimAndNormaliseWhitespace: true)

        let profilePicture = (try? container.select("span.avaHasImage picture").first())
            .flatMap(parsePicture)

        return PostHeader(
            id: postID,
            localURL: localPostURL,
            remoteInstanceLink: nil, // FIXME: the HTML from the mobile version that we use as data source doesn't contain the link to a remote server.
            localAuthorID: authorURL,
            authorName: authorName,
            date: date,
            authorProfilePicture: profilePicture?.url.map(ImageLocation.remote),
        )
    }

    private static func parseSinglePhoto(_ link: Element) -> PhotoAttachment? {
        let dataPv = try? Data(link.attr(Array("data-pv".utf8)))
        let sizes = dataPv.flatMap {
            try? JSONDecoder().decode(PhotoViewerInlineData.self, from: $0)
        }
        guard let picture = try? link.select("picture").first.flatMap(parsePicture) else {
            return nil
        }
        return PhotoAttachment(
            blurHash: picture.blurHash,
            thumbnail: picture.url.map(ImageLocation.remote),
            sizes: sizes?.urls ?? [],
            altText: picture.altText,
        )
    }

    private static func parsePostAttachments(
        _ postAttachments: Element?
    ) throws -> [PostAttachment] {
        guard let postAttachments, postAttachments.hasClass("postAttachments") else {
            return []
        }
        let photos = try postAttachments
            .select("a.photo")
            .compactMap { parseSinglePhoto($0).map(PostAttachment.photo) }
        return photos
    }

    static func deserializeResult(from document: Document) throws -> FeedResponse {
        let createWallPostURL = try document
            .select("#wallPostFormForm_feed")
            .first()?
            .attr("action")

        let userID = createWallPostURL
            .flatMap {
                userIDRegex.firstMatch(in: $0, captureGroup: 1)
            }
            .flatMap { Int($0) }
            .map(UserID.init)
            ?? UserID(rawValue: -1)

        var posts: [Post] = []
        for postElement in try document.select(".post") {
            do {
                guard
                    let postHeader = try parseSinglePost(
                        postElement,
                        authorNameLinkSelector: "a.authorName",
                        postLinkSelector: "a.postLink",
                    )
                else { continue }

                let postContent = try postElement.select(".postContent").first()
                let text = (try? postContent?.select(".expandableText .full").first())
                    ?? postContent

                let attachments =
                    try parsePostAttachments(postContent?.nextElementSibling())

                func actionCount(_ actionName: String) throws -> Int {
                    try
                        (postElement
                        .select(".postActions .action.\(actionName) .counter")
                        .first()?
                        .text(trimAndNormaliseWhitespace: true)).flatMap(Int.init) ?? 0
                }

                let likeCount = try actionCount("like")
                let repostCount = try actionCount("share")
                let replyCount = try actionCount("comment")
                let liked = try !postElement.select(".postActions .action.like.liked")
                    .isEmpty()

                let reposts =
                    try postElement
                    .select(".repostHeader")
                    .compactMap { repostHeaderElement -> Repost? in
                        guard
                            let repostHeader = try parseSinglePost(
                                repostHeaderElement,
                                authorNameLinkSelector: "a.name",
                                postLinkSelector: "a.grayText",
                            )
                        else { return nil }

                        let postContent = try repostHeaderElement.nextElementSibling()
                        let text =
                            (try? postContent?.select(".expandableText .full").first())
                            ?? postContent
                        let isMastodonStyle = try
                            !repostHeaderElement
                            .select(".repostIcon.mastodonStyle").isEmpty()

                        let attachments =
                            try parsePostAttachments(postContent?.nextElementSibling())

                        return Repost(
                            header: repostHeader,
                            text: text.map(PostText.init) ?? PostText(),
                            isMastodonStyleRepost: isMastodonStyle,
                            attachments: attachments,
                        )
                    }

                posts.append(
                    Post(
                        header: postHeader,
                        text: text.map(PostText.init) ?? PostText(),
                        likeCount: likeCount,
                        replyCount: replyCount,
                        repostCount: repostCount,
                        liked: liked,
                        reposted: reposts,
                        attachments: attachments,
                    )
                )
            } catch {
                continue
            }
        }
        return FeedResponse(posts: posts, currentUserID: userID)
    }
}

struct FeedResponse {
    var posts: [Post]
    var currentUserID: UserID
}

private let userIDRegex =
    try! NSRegularExpression(pattern: "/users/([0-9]+)/createWallPost")
