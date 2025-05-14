import Foundation

enum ImageLocation: Equatable {
    case remote(URL)
    case bundled(ImageResource)
}
