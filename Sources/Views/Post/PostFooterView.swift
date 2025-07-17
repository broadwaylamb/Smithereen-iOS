import SwiftUI

struct PostFooterView: View {
    var replyCount: Int
    var repostCount: Int
    var likesCount: Int
    var liked: Bool

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        HStack(spacing: horizontalSizeClass == .regular ? 0 : 8) {
            CommentButton(count: replyCount)
            Spacer()
            RepostButton(count: repostCount)
            LikeButton(count: likesCount, liked: liked)
        }
        .font(horizontalSizeClass == .regular ? .callout : .caption)
    }
}

private struct CompactPostFooterButton<Image: View>: View {
    var alignment: VerticalAlignment
    var image: Image
    var count: Int
    var highlighted: Bool
    var action: @MainActor () -> Void

    @EnvironmentObject private var palette: PaletteHolder

    var body: some View {
        Button(action: action) {
            HStack(alignment: alignment, spacing: 6) {
                image
                if count != 0 {
                    Text(
                        "\(count)",
                        comment: "The number of comments/likes/reposts of a post"
                    )
                    .fontWeight(.bold)
                }
            }
        }
        .padding(0)
        .buttonStyle(.bordered)
        .buttonBorderShape(.roundedRectangle(radius: 4))
        .tint(
            highlighted
                ? palette.compactPostButtonHighlightedTint : palette.compactPostButtonTint
        )
        .frame(minWidth: 40, minHeight: 26, maxHeight: 26)
    }
}

private struct CommentButton: View {
    var count: Int

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject private var palette: PaletteHolder

    private func action() {
        // TODO
    }

    var body: some View {
        if horizontalSizeClass == .regular {
            Button(action: action) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Image(.commentOutline)
                        .alignmentGuide(.firstTextBaseline) { $0.height - 4 }
                    if count == 0 {
                        Text(
                            "Comment",
                            comment: "A button when there are no comments in a post; imperative.",
                        )
                    } else {
                        Text(
                            "\(count) comments",
                            comment: "The number of comments of a post",
                        )
                    }
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 14)
            }
            .buttonStyle(.borderless)
            .tint(palette.regularPostCommentButton)
        } else {
            CompactPostFooterButton(
                alignment: .firstTextBaseline,
                image:
                    Image(.commentFilled)
                        .resizable()
                        .frame(width: 15, height: 14)
                        .alignmentGuide(.firstTextBaseline) { $0.height - 3.5 },
                count: count,
                highlighted: false,
                action: action,
            )
        }
    }
}

private struct RepostButton: View {
    var count: Int

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject private var palette: PaletteHolder

    private func action() {
        // TODO
    }

    var body: some View {
        if horizontalSizeClass == .regular {
            Button(action: action) {
                HStack(spacing: 8) {
                    Image(.repostOutline)
                    if count != 0 {
                        Text("\(count)", comment: "The number of reposts of a post")
                            .fontWeight(.semibold)
                    }
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 14)
            }
            .buttonStyle(.borderless)
            .tint(palette.regularPostLikeAndRepostButton)
        } else {
            CompactPostFooterButton(
                alignment: .center,
                image:
                    Image(.repostFilled)
                    .resizable()
                    .frame(width: 15, height: 14),
                count: count,
                highlighted: false,
                action: action,
            )
        }
    }
}

private struct LikeButton: View {
    @State var count: Int
    @State var liked: Bool

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject private var palette: PaletteHolder

    private func action() {
        withAnimation(.easeInOut(duration: 0.2)) {
            liked.toggle()
            if liked {
                count += 1
            } else {
                count -= 1
            }
        }
        // TODO: Actually send the like to the server
        // If the server returned an error, reset `liked` and `count` to previous state
    }

    var body: some View {
        if horizontalSizeClass == .regular {
            Button(action: action) {
                HStack(spacing: 8) {
                    Text("Like")
                        .tint(palette.regularPostLikeText)
                    Image(liked ? .likeFilled : .likeOutline)
                    if count != 0 {
                        Text("\(count)", comment: "The number of likes of a post")
                            .fontWeight(.semibold)
                    }
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 14)
            }
            .buttonStyle(.borderless)
            .tint(palette.regularPostLikeAndRepostButton)
            .likeButtonFeedback(liked: liked)
        } else {
            CompactPostFooterButton(
                alignment: .center,
                image: Image(.likeFilled)
                    .resizable()
                    .frame(width: 15, height: 13),
                count: count,
                highlighted: liked,
                action: action,
            )
            .likeButtonFeedback(liked: liked)
        }
    }
}

@MainActor
private let impactFBG = UIImpactFeedbackGenerator()

@MainActor
private let notificationFBG = UINotificationFeedbackGenerator()

extension View {

    fileprivate func likeButtonFeedback(liked: Bool) -> some View {
        if #available(iOS 17.0, *) {
            // NOTE: The condition here is inverted because SwiftUI.
            // We want .success when the user likes a post
            // and .impact when the user withdraws their like.
            // Counterintuitive as it is, this condition is correct.
            return sensoryFeedback(liked ? .impact : .success, trigger: liked)
        }
        return onChange(of: liked) { liked in
            if liked {
                notificationFBG.notificationOccurred(.success)
            } else {
                impactFBG.impactOccurred()
            }
        }
    }
}
