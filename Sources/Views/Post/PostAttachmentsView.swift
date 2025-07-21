import SwiftUI
import MediaGridLayout

struct PostAttachmentsView: View {
    var attachments: [PostAttachment]

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject private var palette: PaletteHolder

    private var photos: [PhotoAttachment] {
        attachments.compactMap {
            switch $0 {
            case .photo(let photo):
                return photo
            default:
                return nil
            }
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            Spacer(minLength: 0)
            MediaGridView(
                elements: photos,
                maxWidth: 320,
                maxHeight: 510,
                minHeight: 255,
                gap: 2,
            ) { photo in
                let placeholder = photo.blurHash?.wrappedValue ?? palette.loadingImagePlaceholder
                let cornerRadius = horizontalSizeClass == .regular ? 2.5 : 0
                // TODO: Use the correct URL based on the size
                CacheableAsyncImage(.remote(url)) { image in
                    image.resizable()
                } placeholder: {
                    placeholder
                }
                .aspectRatio(photo.aspectRatio, contentMode: .fit)
                .cornerRadius(cornerRadius)
                .debugBorder()
            }
            .debugBorder()
            Spacer(minLength: 0)
        }
    }
}

extension PhotoAttachment: HasAspectRatio {
    var aspectRatio: Double {
        sizes.first.map { Double($0.width) / Double($0.height) } ?? 1
    }
}
