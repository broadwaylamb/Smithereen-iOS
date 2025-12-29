import Foundation

enum PostAttachment: Equatable {
    case photo(PhotoAttachment)
}

struct PhotoAttachment: Equatable {
    var sizes: [PhotoSizeVariant]
}

struct PhotoViewerInlineData: Codable {
    var urls: [PhotoSizeVariant]
}

struct PhotoSizeVariant: Equatable, Codable {
    var width: Int
    var height: Int
}
