import Foundation

enum PostAttachment: Equatable {
    case photo(PhotoAttachment)
    case video(VideoAttachment)
}

struct PhotoAttachment: Equatable {
    var blurHash: RGBAColor?
    var thumbnailURL: URL?
    var sizes: [PhotoSizeVariant]
    var altText: String?
}

struct PhotoViewerInlineData: Codable {
    var index: Int
    var urls: [PhotoSizeVariant]
}

struct PhotoSizeVariant: Equatable, Codable {
    var webp: URL
    var width: Int
    var height: Int
}

struct VideoAttachment: Equatable {

}
