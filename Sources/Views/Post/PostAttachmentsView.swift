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
            MediaGridLayout(spacing: 2) {
                ForEach(photos.indexed(), id: \.offset) { (_, photo) in
                    let placeholder = photo.blurHash?.wrappedValue
                        ?? palette.loadingImagePlaceholder
                    let cornerRadius = horizontalSizeClass == .regular ? 2.5 : 0

                    // We put the image into an overlay because otherwise it won't be
                    // clipped inside the grid.
                    Color.clear
                        .overlay {
                            // TODO: Use the correct URL based on the size
                            CacheableAsyncImage(.remote(photo.thumbnailURL!)) { image in
                                image.resizable()
                            } placeholder: {
                                placeholder
                            }
                            .aspectRatio(photo.aspectRatio, contentMode: .fill)
                        }
                        .aspectRatioForGridLayout(photo.aspectRatio)
                        .cornerRadius(cornerRadius)
                        .clipped()
                }
            }
            Spacer(minLength: 0)
        }
        .debugBorder(.blue)
        .frame(maxHeight: 510)
    }
}
