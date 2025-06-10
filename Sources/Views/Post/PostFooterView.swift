import SwiftUI

// TODO: Account for large numbers, e.g. shorten 1234 to 1.2K in compact size class
private let numberFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    return formatter
}()

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
    var action: @MainActor () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: alignment, spacing: 6) {
                image
                if count != 0 {
                    Text(verbatim: numberFormatter.string(from: count as NSNumber)!)
                        .fontWeight(.bold)
                }
            }
            .padding(.horizontal, 9)
        }
        .frame(minWidth: 40, minHeight: 26, maxHeight: 26)
        .foregroundStyle(Color(#colorLiteral(red: 0.6374332905, green: 0.6473867297, blue: 0.6686993241, alpha: 1)))
        .background(Color(#colorLiteral(red: 0.9188938141, green: 0.93382442, blue: 0.9421684742, alpha: 1)))
        .cornerRadius(4)
    }
}

private struct CommentButton: View {
    var count: Int

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @AppStorage(.palette) private var palette = .smithereen

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
                        Text("Comment")
                    } else {
                        Text("\(count as NSNumber, formatter: numberFormatter) comments")
                    }
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 14)
                .tint(palette.regularPostCommentButton)
            }
        } else {
            CompactPostFooterButton(
                alignment: .firstTextBaseline,
                image:
                    Image(.commentFilled)
                    .resizable()
                    .frame(width: 15, height: 14)
                    .alignmentGuide(.firstTextBaseline) { $0.height - 3.5 },
                count: count,
                action: action,
            )
        }
    }
}

private struct RepostButton: View {
    var count: Int

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @AppStorage(.palette) private var palette = .smithereen

    private func action() {
        // TODO
    }

    var body: some View {
        if horizontalSizeClass == .regular {
            Button(action: action) {
                HStack(spacing: 8) {
                    Image(.repostOutline)
                    if count != 0 {
                        Text(verbatim: numberFormatter.string(from: count as NSNumber)!)
                            .fontWeight(.semibold)
                    }
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 14)
                .tint(palette.regularPostLikeAndRepostButton)
            }
        } else {
            CompactPostFooterButton(
                alignment: .center,
                image:
                    Image(.repostFilled)
                    .resizable()
                    .frame(width: 15, height: 14),
                count: count,
                action: action,
            )
        }
    }
}

private struct LikeButton: View {
    @State var count: Int
    @State var liked: Bool

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @AppStorage(.palette) private var palette = .smithereen

    private func action() {
        withAnimation(.easeInOut(duration: 0.2)) {
            if liked {
                count -= 1
            } else {
                count += 1
            }
            liked.toggle()
        }
        // TODO: Actually send the like to the server
        // If the server returned an error, reset `liked` to false
    }

    var body: some View {
        if horizontalSizeClass == .regular {
            Button(action: action) {
                HStack(spacing: 8) {
                    Text("Like")
                        .tint(palette.regularPostLikeText)
                    Image(liked ? .likeFilled : .likeOutline)
                    if count != 0 {
                        Text(verbatim: numberFormatter.string(from: count as NSNumber)!)
                            .fontWeight(.semibold)
                    }
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 14)
                .tint(palette.regularPostLikeAndRepostButton)
            }
        } else {
            CompactPostFooterButton(
                alignment: .center,
                image: Image(.likeFilled)
                    .resizable()
                    .frame(width: 15, height: 13),
                count: count,
                action: action,
            )
        }
    }
}
