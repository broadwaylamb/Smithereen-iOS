import Foundation
import Hammond
import SwiftSoup

@GET("/feed")
@EncodableRequest
struct FeedRequest: DecodableRequestProtocol {
    @Query var start: Int?
    @Query var offset: Int?

    private static func parsePicture(_ element: Element) -> URL? {
        do {
            for resource in try element.select("source") {
                if try resource.attr("type") != "image/webp" {
                    continue
                }
                let srcsets = try resource.attr("srcset")
                    .split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespaces) }

                for srcset in srcsets {
                    if srcset.hasSuffix(" 2x") {
                        return URL(string: String(srcset.prefix(srcset.count - 3)))
                    }
                }
            }
        } catch {
            // If there is an error, we ignore it and return nil
        }
        return nil
    }

    private static func parseSinglePost(
        _ container: Element,
        authorNameLinkSelector: String,
        postLinkSelector: String,
    ) throws -> PostHeader? {
        guard let authorNameLink = try container.select(authorNameLinkSelector).first(),
              let authorURL = try URL(string: authorNameLink.attr("href")) else {
            return nil
        }

        let authorName = try authorNameLink.text(trimAndNormaliseWhitespace: true)

        guard let postLink = try container.select(postLinkSelector).first(),
              let postID = try? postLink
                .attr("href")
                .components(separatedBy: "posts/")
                .last
                .flatMap(Int.init)
        else {
            return nil
        }
        let date = try postLink.text(trimAndNormaliseWhitespace: true)

        let profilePicture = (try? container.select("span.avaHasImage picture").first())
            .flatMap(parsePicture)

        return PostHeader(
            id: PostID(rawValue: postID),
            remoteInstanceLink: nil, // FIXME: the HTML from the mobile version that we use as data source doesn't contain the link to a remote server.
            localAuthorID: authorURL,
            authorName: authorName,
            date: date,
            authorProfilePicture: profilePicture.map(ImageLocation.remote),
        )
    }

    static func deserializeResult(from document: Document) throws -> [Post] {
        var posts: [Post] = []
        for postElement in try document.select(".post") {
            do {
                guard let postHeader = try parseSinglePost(
                    postElement,
                    authorNameLinkSelector: "a.authorName",
                    postLinkSelector: "a.postLink",
                ) else { continue }

                let postContent = try postElement.select(".postContent").first()
                let text = (try? postContent?.select(".expandableText .full").first()) ?? postContent

                func actionCount(_ actionName: String) throws -> Int {
                    try (
                        postElement
                            .select(".postActions .action.\(actionName) .counter")
                            .first()?
                            .text(trimAndNormaliseWhitespace: true)
                    ).flatMap(Int.init) ?? 0
                }

                let likeCount = try actionCount("like")
                let repostCount = try actionCount("share")
                let replyCount = try actionCount("comment")
                let liked = try !postElement.select(".postActions .action.like.liked").isEmpty()

                let reposts = try postElement
                    .select(".repostHeader")
                    .compactMap { repostHeaderElement -> Repost? in
                        guard let repostHeader = try parseSinglePost(
                            repostHeaderElement,
                            authorNameLinkSelector: "a.name",
                            postLinkSelector: "a.grayText"
                        ) else { return nil }

                        let postContent = try repostHeaderElement.nextElementSibling()
                        let text = (try? postContent?.select(".expandableText .full").first()) ?? postContent
                        let isMastodonStyle = try !repostHeaderElement
                            .select(".repostIcon.mastodonStyle").isEmpty()

                        return Repost(
                            header: repostHeader,
                            text: text.map(PostText.init) ?? PostText(),
                            isMastodonStyleRepost: isMastodonStyle,
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
                    )
                )
            } catch {
                continue
            }
        }
        return posts
    }
}
