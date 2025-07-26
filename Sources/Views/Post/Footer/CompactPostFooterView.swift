import SwiftUI

struct CompactPostFooterView: View {
    var replyCount: Int
    var repostCount: Int
    var likesCount: Int
    var liked: Bool

    var body: some View {
        HStack(spacing: 8) {
            CompactPostFooterButton(
                alignment: .firstTextBaseline,
                image:
                    Image(.commentFilled)
                        .resizable()
                        .frame(width: 15, height: 14)
                        .alignmentGuide(.firstTextBaseline) { $0.height - 3.5 },
                count: replyCount,
                highlighted: false,
                action: { /* TODO */ },
            )
            Spacer()
            CompactPostFooterButton(
                alignment: .center,
                image:
                    Image(.repostFilled)
                    .resizable()
                    .frame(width: 15, height: 14),
                count: repostCount,
                highlighted: false,
                action: { /* TODO */ },
            )
            CompactPostFooterButton(
                alignment: .center,
                image: Image(.likeFilled)
                    .resizable()
                    .frame(width: 15, height: 13),
                count: likesCount,
                highlighted: liked,
                action: { /* TODO */ },
            )
            .likeButtonFeedback(liked: liked)
        }
        .font(.caption)
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
