import SwiftUI

private let horizontalContentPadding: CGFloat = 13
private let attachmentBlockTopPadding: CGFloat = 10
private let maxRepostChainDepth = 3

struct RegularPostView: View {
    @ObservedObject var viewModel: PostViewModel

    @EnvironmentObject private var palette: PaletteHolder

    @ScaledMetric(relativeTo: .body) private var repostVerticalLineThickness = 2

    private func singleRepost(_ repost: Repost, headerOnly: Bool) -> some View {
        VStack(alignment: .leading, spacing: 13) {
            RepostedPostHeaderView(
                postHeader: repost.header,
                repostInfo: RepostInfo(
                    isMastodonStyle: repost.isMastodonStyleRepost,
                    entity: .post, // TODO: Use the actual entity
                ),
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
            PostHeaderView(postHeader: viewModel.header)
                .padding(.horizontal, horizontalContentPadding)
                .padding(.vertical, 13)

            PostTextView(viewModel.text)
                .padding(.horizontal, horizontalContentPadding)

            if !viewModel.attachments.isEmpty {
                PostAttachmentsView(attachments: viewModel.attachments)
                    .padding(.horizontal, horizontalContentPadding)
                    .padding(.top, viewModel.text.isEmpty ? 0 : attachmentBlockTopPadding)
            }

            repostChain(
                viewModel.reposted.prefix(maxRepostChainDepth),
                hasContentAbove: viewModel.hasContent,
            )
            .padding(.horizontal, horizontalContentPadding)

            palette.postFooterSeparator
                .frame(width: .infinity, height: 1)
                .padding(.leading, 16)
                .padding(.top, 15)

            RegularPostFooterView(viewModel: viewModel)
                .padding(.horizontal, horizontalContentPadding)
        }
        .background(Color.white)
        .colorScheme(.light)
        .openURLsInBuiltInBrowser()
        .draggableAsURL(viewModel.originalPostURL)
    }
}
