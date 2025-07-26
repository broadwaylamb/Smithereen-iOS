import SwiftUI

private let horizontalContentPadding: CGFloat = 13
private let attachmentBlockTopPadding: CGFloat = 10
private let maxRepostChainDepth = 3

struct RegularPostView: View {
    var post: Post

    // TODO: Remove this when we add the view model
    @Environment(\.instanceURL) private var instanceURL

    @EnvironmentObject private var palette: PaletteHolder

    @ScaledMetric(relativeTo: .body) private var repostVerticalLineThickness = 2

    private func singleRepost(_ repost: Repost, headerOnly: Bool) -> some View {
        VStack(alignment: .leading, spacing: 13) {
            PostHeaderView(
                postHeader: repost.header,
                kind: .repost(isMastodonStyle: repost.isMastodonStyleRepost),
                horizontalSizeClass: .regular,
            )

            if !headerOnly {
                PostTextView(repost.text)

                if !repost.attachments.isEmpty {
                    PostAttachmentsView(attachments: repost.attachments)
                        .padding(
                            .top,
                            repost.text.isEmpty ? 0 : attachmentBlockTopPadding,
                        )
                }
            }
        }
    }

    @ViewBuilder
    private func repostChain(
        _ reposts: ArraySlice<Repost>,
        hasContentAbove: Bool,
        depth: Int = 1,
    ) -> some View {
        if let repost = reposts.first {
            HStack(spacing: 0) {
                palette
                    .repostVerticalLine
                    .frame(width: repostVerticalLineThickness)
                VStack(alignment: .leading, spacing: 0) {
                    singleRepost(
                        repost,
                        headerOnly: depth >= maxRepostChainDepth,
                    )
                    AnyView(
                        repostChain(
                            reposts.dropFirst(),
                            hasContentAbove: repost.hasContent,
                            depth: depth + 1,
                        )
                    )
                }
                .padding(.leading, 12)
            }
            .padding(.top, hasContentAbove ? 10 : 0)
        } else {
            EmptyView()
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PostHeaderView(
                postHeader: post.header,
                kind: .regular,
                horizontalSizeClass: .regular,
            )
            .padding(.horizontal, horizontalContentPadding)
            .padding(.vertical, 13)

            PostTextView(post.text)
                .padding(.horizontal, horizontalContentPadding)

            if !post.attachments.isEmpty {
                PostAttachmentsView(attachments: post.attachments)
                    .padding(.horizontal, horizontalContentPadding)
                    .padding(.top, post.text.isEmpty ? 0 : attachmentBlockTopPadding)
            }

            repostChain(
                post.reposted.prefix(maxRepostChainDepth),
                hasContentAbove: post.hasContent,
            )
            .padding(.horizontal, horizontalContentPadding)

            palette.postFooterSeparator
                .frame(width: .infinity, height: 1)
                .padding(.leading, 16)
                .padding(.top, 15)

            RegularPostFooterView(
                replyCount: post.replyCount,
                repostCount: post.repostCount,
                likesCount: post.likeCount,
                liked: post.liked,
            )
            .padding(.horizontal, horizontalContentPadding)
        }
        .background(Color.white)
        .colorScheme(.light)
        .draggableAsURL(post.originalPostURL(base: instanceURL))
    }
}
