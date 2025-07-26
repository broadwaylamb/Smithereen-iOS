import SwiftUI

struct UserProfilePictureView: View {
    var location: ImageLocation?

    // TODO: Add a settting whether to display square or round avatars

    @EnvironmentObject private var palette: PaletteHolder

    var body: some View {
        CacheableAsyncImage(
            location,
            content: { $0.resizable() },
            placeholder: { palette.loadingImagePlaceholder },
        )
        .cornerRadius(2.5)
    }
}

#Preview {
    UserProfilePictureView()
}
