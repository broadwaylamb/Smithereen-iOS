import SwiftUI

private let horizontalContentPadding: CGFloat = 4
private let attachmentBlockTopPadding: CGFloat = 6
private let maxRepostChainDepth = 3

struct CompactPostView: View {
    @ObservedObject var viewModel: PostViewModel

    private func singleRepost(_ repost: Repost, headerOnly: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            RepostedPostHeaderView(
                api: viewModel.api,
                postHeader: repost.header,
                repostInfo: RepostInfo(
                    isMastodonStyle: repost.isMastodonStyleRepost,
                    entity: .post, // TODO: Use the actual entity
                ),
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
            PostHeaderView(api: viewModel.api, postHeader: viewModel.header)
                .padding(.horizontal, horizontalContentPadding)
                .padding(.top, 7)
                .padding(.bottom, 13)

            PostTextView(viewModel.text)
                .padding(.horizontal, horizontalContentPadding)

            if !viewModel.attachments.isEmpty {
                PostAttachmentsView(attachments: viewModel.attachments)
                    .padding(.horizontal, 0)
                    .padding(.top, viewModel.text.isEmpty ? 0 : attachmentBlockTopPadding)
            }

            let reposts = viewModel.reposted.prefix(maxRepostChainDepth)
            ForEach(reposts.indexed(), id: \.offset) { (i, repost) in
                let hasTopPadding =
                    i == 0 && viewModel.hasContent || i > 0 && reposts[i - 1].hasContent
                singleRepost(repost, headerOnly: i + 1 >= maxRepostChainDepth)
                    .padding(.top, hasTopPadding ? attachmentBlockTopPadding : 0)
            }

            CompactPostFooterView(viewModel: viewModel)
                .padding(.horizontal, horizontalContentPadding)
                .padding(.top, 13)
                .padding(.bottom, 11)
        }
        .background(Color.white)
        .colorScheme(.light)
        .openURLsInBuiltInBrowser()
        .draggableAsURL(viewModel.originalPostURL)
    }
}
