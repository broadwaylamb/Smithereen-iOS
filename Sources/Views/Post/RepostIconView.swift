import SwiftUI

struct RepostIconView: View {
    var kind: PostKind

    @ScaledMetric(relativeTo: .body)
    private var repostIconSize = 13

    @EnvironmentObject private var palette: PaletteHolder

    private var image: Image? {
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
        if let image {
            image
                .resizable()
                .frame(width: repostIconSize, height: repostIconSize)
                .foregroundStyle(palette.repostIcon)
        }
    }
}
