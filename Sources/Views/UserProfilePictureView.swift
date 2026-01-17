import SwiftUI

struct UserProfilePictureView: View {
    var sizes: ImageSizes

    @EnvironmentObject private var palette: PaletteHolder

    @AppStorage(.roundProfilePictures) private var roundProfilePictures

    private var image: some View {
        GeometryReader { proxy in
            CacheableAsyncImage(
                size: proxy.size,
                sizes: sizes,
                content: { $0.resizable() },
                placeholder: { palette.loadingImagePlaceholder },
            )
        }
    }

    var body: some View {
        if roundProfilePictures {
            image.clipShape(Circle())
        } else {
            image.clipShape(RoundedRectangle(cornerRadius: 2.5))
        }
    }
}

#Preview {
    UserProfilePictureView(sizes: ImageSizes())
        .environmentObject(PaletteHolder())
}
