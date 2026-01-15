import SwiftUI
import SmithereenAPI

private let horizontalContentPadding: CGFloat = 4
private let attachmentBlockTopPadding: CGFloat = 6

struct CompactPostView: View {
    @ObservedObject var viewModel: PostViewModel

    private func singleRepost(
        postID : WallPostID,
        isMastodonStyleRepost: Bool,
        headerOnly: Bool,
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            RepostedPostHeaderView(
                author: viewModel.getAuthor(postID),
                date: viewModel.getPostDate(postID: postID),
                repostInfo: RepostInfo(
                    isMastodonStyle: isMastodonStyleRepost,
                    entity: .post, // TODO: Use the actual entity
                ),
            )
            .padding(.horizontal, 4)

            if !headerOnly {
                let text = viewModel.getText(postID: postID)
                PostTextView(text)
                    .padding(.horizontal, horizontalContentPadding)

                let attachments = viewModel.getAttachments(postID: postID)
                if !attachments.isEmpty {
                    PostAttachmentsView(
                        attachments,
                        unsupportedMessagePadding: horizontalContentPadding,
                    )
                    .padding(.top, text.isEmpty ? 0 : attachmentBlockTopPadding)
                }
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PostHeaderView(author: viewModel.getAuthor(), date: viewModel.getPostDate())
                .padding(.horizontal, horizontalContentPadding)
                .padding(.top, 7)
                .padding(.bottom, 13)

            let text = viewModel.getText()
            PostTextView(text)
                .padding(.horizontal, horizontalContentPadding)

            let attachments = viewModel.getAttachments()
            if !attachments.isEmpty {
                PostAttachmentsView(
                    attachments,
                    unsupportedMessagePadding: horizontalContentPadding,
                )
                .padding(.horizontal, 0)
                .padding(.top, text.isEmpty ? 0 : attachmentBlockTopPadding)
            }

            let repostIDs = viewModel.repostIDs
            ForEach(repostIDs.indexed(), id: \.offset) { (i, repostID) in
                let hasTopPadding =
                    i == 0 && viewModel.hasContent()
                        || i > 0 && viewModel.hasContent(postID: repostID)
                singleRepost(
                    postID: repostID,
                    isMastodonStyleRepost: i == 0 && viewModel.isMastodonStyleRepost,
                    headerOnly: repostIDs.count > 1 && i == repostIDs.count - 1,
                )
                .padding(.top, hasTopPadding ? attachmentBlockTopPadding : 0)
            }

            CompactPostFooterView(viewModel: viewModel)
                .padding(.horizontal, horizontalContentPadding)
                .padding(.top, 13)
                .padding(.bottom, 11)
        }
        .background(Color.white)
        .colorScheme(.light)
        .openLinks()
        .draggableAsURL(viewModel.originalPostURL)
    }
}
