import SwiftUI

struct PostHeaderView: View {
    var postHeader: PostHeader
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        GenericPostHeaderView(
            postHeader: postHeader,
            kind: .regular,
            horizontalSizeClass: horizontalSizeClass,
            repostIcon: {
                EmptyView()
            },
            detailsButton: {
                Button(action: { /* TODO */ }) {
                    Image(.ellipsis)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Post settings")
            },
        )
    }
}

struct RepostedPostHeaderView: View {
    var postHeader: PostHeader
    var repostInfo: RepostInfo

    @EnvironmentObject private var palette: PaletteHolder

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @ScaledMetric(relativeTo: .body)
    private var repostIconSize = 13

    private var image: Image {
        repostInfo.isMastodonStyle
            ? Image(.repostHeaderMastodonStyle)
            : Image(.repostHeaderQuote)
    }

    var body: some View {
        GenericPostHeaderView(
            postHeader: postHeader,
            kind: .repost(repostInfo),
            horizontalSizeClass: horizontalSizeClass,
            repostIcon: {
                image
                    .resizable()
                    .frame(width: repostIconSize, height: repostIconSize)
                    .foregroundStyle(palette.repostIcon)
            },
            detailsButton: {
                EmptyView()
            },
        )
    }
}

private struct GenericPostHeaderView<RepostIcon: View, DetailsButton: View>: View {
    var postHeader: PostHeader
    var kind: PostKind
    var repostIcon: () -> RepostIcon
    var detailsButton: () -> DetailsButton

    @EnvironmentObject private var palette: PaletteHolder

    @ScaledMetric private var imageSize: CGFloat

    @Environment(\.pushToNavigationStack) private var pushToNavigationStack

    init(
        postHeader: PostHeader,
        kind: PostKind,
        horizontalSizeClass: UserInterfaceSizeClass?,
        @ViewBuilder repostIcon: @escaping () -> RepostIcon,
        @ViewBuilder detailsButton: @escaping () -> DetailsButton,
    ) {
        self.postHeader = postHeader
        self.kind = kind
        let imageSize: CGFloat =
            switch (kind, horizontalSizeClass) {
            case (.regular, .regular):
                55
            case (.regular, _):
                40
            case (_, .regular):
                50
            case (_, _):
                32
            }
        self._imageSize = ScaledMetric(wrappedValue: imageSize, relativeTo: .body)
        self.repostIcon = repostIcon
        self.detailsButton = detailsButton
    }

    private func userProfileLink(@ViewBuilder label: () -> some View) -> some View {
        Button(
            action: {
                pushToNavigationStack(
                    UserProfileNavigationItem(
                        firstName: postHeader.authorName,
                        userIDOrHandle: .right(postHeader.authorHandle))
                )
            },
            label: label
        )
        .buttonStyle(.borderless)
    }

    var body: some View {
        HStack(spacing: 8) {
            userProfileLink {
                UserProfilePictureView(location: postHeader.authorProfilePicture)
                    .frame(width: imageSize, height: imageSize)
            }
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .center, spacing: 6) {
                    repostIcon()
                    userProfileLink {
                        Text(postHeader.authorName)
                            .bold()
                            .foregroundStyle(palette.accent)
                    }
                }
                Button(kind.grayText(postHeader.date)) {
                    // TODO: Navigate to the post
                }
                .buttonStyle(.borderless)
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer()
            detailsButton()
        }
    }
}
