import SwiftUI

struct RegularPostFooterView: View {
    var replyCount: Int
    var repostCount: Int
    var likesCount: Int
    var liked: Bool

    @EnvironmentObject private var palette: PaletteHolder

    private var commentButtonText: Text {
        if replyCount == 0 {
            Text(
                "Comment",
                comment: "A button when there are no comments in a post; imperative.",
            )
        } else {
            Text(
                "\(replyCount) comments",
                comment: "The number of comments of a post",
            )
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            Button(action: { /* TODO */ }) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Image(.commentOutline)
                        .alignmentGuide(.firstTextBaseline) { $0.height - 4 }
                    commentButtonText
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 14)
            }
            .buttonStyle(.borderless)
            .tint(palette.regularPostCommentButton)

            Spacer()

            Group {
                Button(action: { /* TODO */ }) {
                    HStack(spacing: 8) {
                        Image(.repostOutline)
                        if repostCount != 0 {
                            Text(
                                "\(repostCount)",
                                comment: "The number of reposts of a post"
                            )
                            .fontWeight(.semibold)
                        }
                    }
                    .padding(.horizontal, 15)
                    .padding(.vertical, 14)
                }

                Button(action: { /* TODO */ }) {
                    HStack(spacing: 8) {
                        Text("Like")
                            .tint(palette.regularPostLikeText)
                        Image(liked ? .likeFilled : .likeOutline)
                        if likesCount != 0 {
                            Text(
                                "\(likesCount)",
                                comment: "The number of likes of a post"
                            )
                            .fontWeight(.semibold)
                        }
                    }
                    .padding(.horizontal, 15)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.borderless)
                .tint(palette.regularPostLikeAndRepostButton)
                .likeButtonFeedback(liked: liked)
            }
            .buttonStyle(.borderless)
            .tint(palette.regularPostLikeAndRepostButton)
        }
        .font(.callout)
    }
}

