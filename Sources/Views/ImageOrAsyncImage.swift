import SwiftUI

enum ImageOrAsyncImage<Content: View>: View {
    case image(Image)
    case asyncImage(AsyncImage<Content>)

    var body: some View {
        switch self {
        case .image(let image):
            image
        case .asyncImage(let image):
            image
        }
    }
}

extension ImageOrAsyncImage {
    func resizable(
        capInsets: EdgeInsets = EdgeInsets(),
        resizingMode: Image.ResizingMode = .stretch
    ) -> Self {
        switch self {
        case .image(let image):
            return .image(
                image.resizable(capInsets: capInsets, resizingMode: resizingMode)
            )
        case .asyncImage:
            return self
        }
    }
}
