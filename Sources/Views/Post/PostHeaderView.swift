import SwiftUI

struct PostHeaderView: View {
    var postHeader: PostHeader
    var kind: PostKind

    @EnvironmentObject private var palette: PaletteHolder

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @ScaledMetric private var imageSize: CGFloat

    init(
        postHeader: PostHeader,
        kind: PostKind,
        horizontalSizeClass: UserInterfaceSizeClass?,
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
            CacheableAsyncImage(
                postHeader.authorProfilePicture,
                content: { $0.resizable() },
                placeholder: { palette.loadingImagePlaceholder },
            )
            .frame(width: imageSize, height: imageSize)
            .cornerRadius(2.5)
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .center, spacing: 6) {
                    RepostIconView(kind: kind)
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
