import SwiftUI

struct RegularPostFooterView: View {
    @ObservedObject var viewModel: PostViewModel

    @EnvironmentObject private var palette: PaletteHolder

    @EnvironmentObject private var errorObserver: ErrorObserver
    @State private var composeRepostIsShown = false

    var body: some View {
        HStack(spacing: 0) {
            Button(action: { /* TODO */ }) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Image(.commentOutline)
                        .alignmentGuide(.firstTextBaseline) { $0.height - 4 }
                    Text(
                        "\(viewModel.commentCount) comments",
                        comment: """
                        The number of comments of a post. \
                        If the number is 0, should be imperative
                        """,
                    )
                    .contentTransitionIfAvailable(
                        .numericText(value: Double(viewModel.commentCount))
                    )
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 14)
            }
            .buttonStyle(.borderless)
            .tint(palette.regularPostCommentButton)

            Spacer()

            Group {
                Button {
                    composeRepostIsShown = true
                } label: {
                    HStack(spacing: 8) {
                        Image(viewModel.reposted ? .repostFilled : .repostOutline)
                        if viewModel.repostCount != 0 {
                            Text(
                                "\(viewModel.repostCount)",
                                comment: "The number of reposts of a post"
                            )
                            .fontWeight(.semibold)
                            .contentTransitionIfAvailable(
                                .numericText(value: Double(viewModel.repostCount))
                            )
                        }
                    }
                    .padding(.horizontal, 15)
                    .padding(.vertical, 14)
                }

                Button(action: viewModel.like) {
                    HStack(spacing: 8) {
                        Text("Like")
                            .tint(palette.regularPostLikeText)
                        Image(viewModel.liked ? .likeFilled : .likeOutline)
                        if viewModel.likeCount != 0 {
                            Text(
                                "\(viewModel.likeCount)",
                                comment: "The number of likes of a post"
                            )
                            .fontWeight(.semibold)
                            .contentTransitionIfAvailable(
                                .numericText(value: Double(viewModel.likeCount))
                            )
                        }
                    }
                    .padding(.horizontal, 15)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.borderless)
                .tint(palette.regularPostLikeAndRepostButton)
                .likeButtonFeedback(liked: viewModel.liked)
            }
            .buttonStyle(.borderless)
            .tint(palette.regularPostLikeAndRepostButton)
        }
        .font(.callout)
        .sheet(isPresented: $composeRepostIsShown) {
            ComposePostView
                .forRepost(
                    isShown: $composeRepostIsShown,
                    errorObserver: errorObserver,
                    repostedPostViewModel: viewModel,
                )
        }
    }
}

