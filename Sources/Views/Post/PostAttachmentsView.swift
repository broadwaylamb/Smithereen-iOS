import SwiftUI

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

    private func photo(_ photo: PhotoAttachment, url: URL) -> some View {
        AsyncImage(url: url, scale: 2) { image in
            image.resizable()
        } placeholder: {
            photo.blurHash?.wrappedValue ?? palette.loadingImagePlaceholder
        }
        .aspectRatio(
            photo.sizes.first.map { CGFloat($0.width) / CGFloat($0.height) },
            contentMode: .fit,
        )
        .cornerRadius(horizontalSizeClass == .regular ? 2.5 : 0)
    }

    var body: some View {
        if let photo = photos.first, let url = photo.thumbnailURL {
            // TODO: Support more photos
            HStack(spacing: 0) {
                Spacer(minLength: 0)
                self.photo(photo, url: url)
                    .frame(maxHeight: 510)
                Spacer(minLength: 0)
            }
        } else {
            EmptyView()
        }
    }
}
