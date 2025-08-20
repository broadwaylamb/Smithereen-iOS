import SwiftUI

struct PostHeaderView: View {
    var api: any APIService
    var postHeader: PostHeader
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        GenericPostHeaderView(
            api: api,
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
    var api: any APIService
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
            api: api,
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
    var api: any APIService
    var postHeader: PostHeader
    var kind: PostKind
    var repostIcon: () -> RepostIcon
    var detailsButton: () -> DetailsButton

    @EnvironmentObject private var palette: PaletteHolder

    @ScaledMetric private var imageSize: CGFloat

    @State private var userProfileLinkActive = false

    init(
        api: any APIService,
        postHeader: PostHeader,
        kind: PostKind,
        horizontalSizeClass: UserInterfaceSizeClass?,
        @ViewBuilder repostIcon: @escaping () -> RepostIcon,
        @ViewBuilder detailsButton: @escaping () -> DetailsButton,
    ) {
        self.api = api
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
        Button(action: {
            userProfileLinkActive = true
        }, label: label)
            .buttonStyle(.borderless)
            .background {
                // This is a hack. When a NavigationLink is inside a List,
                // it's rendered with an arrow. We don't want that arrow.
                NavigationLink(isActive: $userProfileLinkActive) {
                    UserProfileView(
                        firstName: postHeader.authorName, // TODO: Sould be first name
                        viewModel: UserProfileViewModel(
                            api: api,
                            userIDOrHandle: .right(postHeader.authorHandle)
                        )
                    )
                } label: {
                    EmptyView()
                }.opacity(0)
            }
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
