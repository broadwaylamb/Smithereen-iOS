import SwiftUI
import SmithereenAPI

struct PostHeaderView: View {
    var author: PostAuthor
    var date: String
    var originalURL: URL
    var canDelete: Bool
    var canEdit: Bool
    var canPin: Bool
    var isOwnPost: Bool

    init(_ viewModel: PostViewModel) {
        author = viewModel.getAuthor()
        date = viewModel.getPostDate()
        originalURL = viewModel.originalPostURL
        canDelete = viewModel.post.canDelete
        canEdit = viewModel.post.canEdit
        canPin = viewModel.post.canPin ?? false
        isOwnPost = viewModel.isOwnPost
    }

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.openURL) private var openURL

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
                Menu {
                    Button("Open in Browser") {
                        openURL(originalURL)
                    }
                    Button("Copy Link to Post") {
                        UIPasteboard.general.url = originalURL
                        // TODO: Show a message that the link has been copied
                    }
                    Divider()
                    if canPin {
                        Button("Pin Post") {
                            // TODO: Pin post
                        }
                    }
                    if canEdit {
                        Button("Edit Post") {
                            // TODO: Edit post
                        }
                    }
                    if canDelete {
                        Button("Delete Post", role: .destructive) {
                            // TODO: Delete post
                        }
                    }
                    if !isOwnPost {
                        Divider()
                        Button("Report") {
                            // TODO: Reports
                        }
                        Button("Hide News") {
                            // TODO: Hide news
                        }
                    }
                } label: {
                    Image(.ellipsis)
                        // Pad the touch area to 32x32
                        .padding(
                            EdgeInsets(top: 12.5, leading: 6, bottom: 12.5, trailing: 6)
                        )
                }
                .menuStyle(.borderlessButton)
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
                UserProfilePictureView(sizes: author.profilePictureSizes)
                    .frame(width: imageSize, height: imageSize)
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
