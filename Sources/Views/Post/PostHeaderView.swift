import SwiftUI

struct PostHeaderView: View {
    var postHeader: PostHeader
    var kind: Kind

    enum Kind {
        case regular
        case repost(isMastodonStyle: Bool)
        case commentRepost(inReplyTo: String, isMastodonStyle: Bool)
        case commentToDeletedPostRepost(isMastodonStyle: Bool)
    }

    @EnvironmentObject private var palette: PaletteHolder

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @ScaledMetric private var imageSize: CGFloat

    init(
        postHeader: PostHeader,
        kind: Kind,
        horizontalSizeClass: UserInterfaceSizeClass?,
    ) {
        self.postHeader = postHeader
        self.kind = kind
        let imageSize: CGFloat = switch (kind, horizontalSizeClass) {
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
    }

    @ViewBuilder
    private var profilePictureImage: some View {
        switch postHeader.authorProfilePicture {
        case .remote(let url):
            AsyncImage(
                url: url,
                scale: 2.0,
                content: { $0.resizable() },
                placeholder: { palette.loadingImagePlaceholder },
            )
        case .bundled(let resource):
            Image(resource)
                .resizable()
        case nil:
            Color.red // TODO
        }
    }

    private var grayText: LocalizedStringKey {
        switch kind {
        case .regular, .repost:
            "\(postHeader.date)"
        case .commentRepost(let inReplyTo, _):
            "\(postHeader.date) on post \(inReplyTo)"
        case .commentToDeletedPostRepost:
            "\(postHeader.date) on a deleted post"
        }
    }

    @ScaledMetric(relativeTo: .body)
    private var repostIconSize = 13

    private var repostIcon: Image? {
        switch kind {
        case .regular:
            nil
        case .repost(isMastodonStyle: false),
             .commentRepost(_, isMastodonStyle: false),
             .commentToDeletedPostRepost(isMastodonStyle: false):
            Image(.repostHeaderQuote)
        case .repost(isMastodonStyle: true),
             .commentRepost(_, isMastodonStyle: true),
             .commentToDeletedPostRepost(isMastodonStyle: true):
            Image(.repostHeaderMastodonStyle)
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            profilePictureImage
                .frame(width: imageSize, height: imageSize)
                .cornerRadius(2.5)
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .center, spacing: 6) {
                    if let repostIcon {
                        repostIcon
                            .resizable()
                            .frame(width: repostIconSize, height: repostIconSize)
                            .foregroundStyle(palette.repostIcon)
                    }
                    Text(postHeader.authorName)
                        .bold()
                        .foregroundStyle(palette.accent)
                }
                Button(grayText) {
                    // TODO: Navigate to the post
                }
                .buttonStyle(.borderless)
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            if case .regular = kind {
                Spacer()
                Button(action: { /* TODO */ }) {
                    Image(.ellipsis)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Post settings")
            }
        }
    }
}
