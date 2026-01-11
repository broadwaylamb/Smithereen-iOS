import SwiftUI
import SmithereenAPI

struct PostHeaderView: View {
    var author: PostAuthor
    var date: String
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        GenericPostHeaderView(
            kind: .regular,
            author: author,
            date: date,
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
    var author: PostAuthor
    var date: String
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
            kind: .repost(repostInfo),
            author: author,
            date: date,
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
    var kind: PostKind
    var author: PostAuthor
    var date: String
    var repostIcon: () -> RepostIcon
    var detailsButton: () -> DetailsButton

    @EnvironmentObject private var palette: PaletteHolder

    @ScaledMetric private var imageSize: CGFloat

    @Environment(\.displayScale) private var displayScale: CGFloat

    @Environment(\.pushToNavigationStack) private var pushToNavigationStack

    init(
        kind: PostKind,
        author: PostAuthor,
        date: String,
        horizontalSizeClass: UserInterfaceSizeClass?,
        @ViewBuilder repostIcon: @escaping () -> RepostIcon,
        @ViewBuilder detailsButton: @escaping () -> DetailsButton,
    ) {
        self.kind = kind
        self.author = author
        self.date = date
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
                if let userID = author.id?.userID {
                    pushToNavigationStack(UserProfileNavigationItem(userID: userID))
                } else if let _ = author.id?.groupID {
                    // TODO: Navigate to group
                } else {
                    pushToNavigationStack(UserProfileNavigationItem(userID: nil))
                }
            },
            label: label
        )
        .buttonStyle(.borderless)
    }

    var body: some View {
        HStack(spacing: 8) {
            userProfileLink {
                UserProfilePictureView(
                    location: author
                        .profilePictureSizes
                        .sizeThatFits(square: imageSize, scale: displayScale)
                ).frame(width: imageSize, height: imageSize)
            }
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .center, spacing: 6) {
                    repostIcon()
                    userProfileLink {
                        Text(author.displayedName)
                            .bold()
                            .foregroundStyle(palette.accent)
                    }
                }
                Button(kind.grayText(date)) {
                    // TODO: Navigate to the post
                }
                .buttonStyle(.borderless)
                .font(.caption)
                .foregroundStyle(palette.grayText)
            }
            Spacer()
            detailsButton()
        }
    }
}
