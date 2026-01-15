import SwiftUI

struct UserProfilePictureView: View {
    var location: ImageLocation?

    @EnvironmentObject private var palette: PaletteHolder

    @AppStorage(.roundProfilePictures) private var roundProfilePictures

    private var image: some View {
        CacheableAsyncImage(
            location,
            aspectRatio: 1,
            content: { $0.resizable() },
            placeholder: { palette.loadingImagePlaceholder },
        )
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
    UserProfilePictureView()
        .environmentObject(PaletteHolder())
}
