import SwiftUI
import SmithereenAPI

private let horizontalContentPadding: CGFloat = 13
private let attachmentBlockTopPadding: CGFloat = 10
private let maxRepostChainDepth = 3

struct RegularPostView: View {
    @ObservedObject var viewModel: PostViewModel

    @EnvironmentObject private var palette: PaletteHolder

    @ScaledMetric(relativeTo: .body) private var repostVerticalLineThickness = 2

    private func singleRepost(
        postID: WallPostID,
        isMastodonStyleRepost: Bool,
        headerOnly: Bool,
    ) -> some View {
        VStack(alignment: .leading, spacing: 13) {
            RepostedPostHeaderView(
                author: viewModel.getAuthor(postID),
                date: viewModel.getPostDate(postID: postID),
                repostInfo: RepostInfo(
                    isMastodonStyle: isMastodonStyleRepost,
                    entity: .post, // TODO: Use the actual entity
                ),
            )

            if !headerOnly {
                let text = viewModel.getText(postID: postID)
                PostTextView(text)

                let attachments = viewModel.getAttachments(postID: postID)
                if !attachments.isEmpty {
                    PostAttachmentsView(attachments)
                        .padding(.top, text.isEmpty ? 0 : attachmentBlockTopPadding)
                }
            }
        }
    }

    @ViewBuilder
    private func repostChain(
        _ repostIDs: ArraySlice<WallPostID>,
        hasContentAbove: Bool,
        depth: Int = 1,
    ) -> some View {
        if let repostID = repostIDs.first {
            HStack(spacing: 0) {
                palette
                    .repostVerticalLine
                    .frame(width: repostVerticalLineThickness)
                VStack(alignment: .leading, spacing: 0) {
                    singleRepost(
                        postID: repostID,
                        isMastodonStyleRepost: depth == 1 && viewModel.isMastodonStyleRepost,
                        headerOnly: depth >= maxRepostChainDepth,
                    )
                    AnyView(
                        repostChain(
                            repostIDs.dropFirst(),
                            hasContentAbove: viewModel.hasContent(postID: repostID),
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
            PostHeaderView(viewModel)
                .padding(.horizontal, horizontalContentPadding)
                .padding(.vertical, 13)

            let text = viewModel.getText()
            PostTextView(text)
                .padding(.horizontal, horizontalContentPadding)

            let attachments = viewModel.getAttachments()
            if !attachments.isEmpty {
                PostAttachmentsView(attachments)
                    .padding(.horizontal, horizontalContentPadding)
                    .padding(.top, text.isEmpty ? 0 : attachmentBlockTopPadding)
            }

            repostChain(
                ArraySlice(viewModel.repostIDs),
                hasContentAbove: viewModel.hasContent(),
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
        .openLinks()
        .draggableAsURL(viewModel.originalPostURL)
    }
}
