import SwiftUI

struct CompactPostFooterView: View {
    @ObservedObject var viewModel: PostViewModel

    @EnvironmentObject private var errorObserver: ErrorObserver
    @State private var composeRepostIsShown = false

    var body: some View {
        HStack(spacing: 8) {
            CompactPostFooterButton(
                alignment: .firstTextBaseline,
                image:
                    Image(.commentFilled)
                        .resizable()
                        .frame(width: 15, height: 14)
                        .alignmentGuide(.firstTextBaseline) { $0.height - 3.5 },
                count: viewModel.commentCount,
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
                count: viewModel.repostCount,
                highlighted: viewModel.reposted,
                action: {
                    composeRepostIsShown = true
                },
            )
            CompactPostFooterButton(
                alignment: .center,
                image: Image(.likeFilled)
                    .resizable()
                    .frame(width: 15, height: 13),
                count: viewModel.likeCount,
                highlighted: viewModel.liked,
                action: viewModel.like,
            )
            .likeButtonFeedback(liked: viewModel.liked)
        }
        .font(.caption)
        .sheet(isPresented: $composeRepostIsShown) {
            ComposePostView.forRepost(
                isShown: $composeRepostIsShown,
                errorObserver: errorObserver,
                repostedPostViewModel: viewModel,
            )
        }
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
                    .contentTransitionIfAvailable(.numericText(value: Double(count)))
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
