import SwiftUI

private let horizontalContentPadding: CGFloat = 4
private let attachmentBlockTopPadding: CGFloat = 6
private let maxRepostChainDepth = 3

struct CompactPostView: View {
    var post: Post

    // TODO: Remove this when we add the view model
    @Environment(\.instanceURL) private var instanceURL

    private func singleRepost(_ repost: Repost, headerOnly: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            PostHeaderView(
                postHeader: repost.header,
                kind: .repost(isMastodonStyle: repost.isMastodonStyleRepost),
                horizontalSizeClass: .compact,
            )
            .padding(.horizontal, 4)

            if !headerOnly {
                PostTextView(repost.text)
                    .padding(.horizontal, 4)

                if !repost.attachments.isEmpty {
                    PostAttachmentsView(attachments: repost.attachments)
                        .padding(
                            .top,
                            repost.text.isEmpty ? 0 : attachmentBlockTopPadding
                        )
                }
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PostHeaderView(
                postHeader: post.header,
                kind: .regular,
                horizontalSizeClass: .compact,
            )
            .padding(.horizontal, horizontalContentPadding)
            .padding(.top, 7)
            .padding(.bottom, 13)

            PostTextView(post.text)
                .padding(.horizontal, horizontalContentPadding)

            if !post.attachments.isEmpty {
                PostAttachmentsView(attachments: post.attachments)
                    .padding(.horizontal, 0)
                    .padding(.top, post.text.isEmpty ? 0 : attachmentBlockTopPadding)
            }

            let reposts = post.reposted.prefix(maxRepostChainDepth)
            ForEach(reposts.indexed(), id: \.offset) { (i, repost) in
                let hasTopPadding =
                    i == 0 && post.hasContent || i > 0 && reposts[i - 1].hasContent
                singleRepost(repost, headerOnly: i + 1 >= maxRepostChainDepth)
                    .padding(.top, hasTopPadding ? attachmentBlockTopPadding : 0)
            }

            CompactPostFooterView(
                replyCount: post.replyCount,
                repostCount: post.repostCount,
                likesCount: post.likeCount,
                liked: post.liked,
            )
            .padding(.horizontal, horizontalContentPadding)
            .padding(.top, 13)
            .padding(.bottom, 11)
        }
        .background(Color.white)
        .colorScheme(.light)
        .draggableAsURL(post.originalPostURL(base: instanceURL))
    }
}
