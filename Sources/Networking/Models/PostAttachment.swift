import Foundation

enum PostAttachment: Equatable {
    case photo(PhotoAttachment)
    case video(VideoAttachment)
}

struct PhotoAttachment: Equatable {
    var blurHash: RGBAColor?
    var thumbnail: ImageLocation?
    var sizes: [PhotoSizeVariant]
    var altText: String?
}

struct PhotoViewerInlineData: Codable {
    var index: Int
    var urls: [PhotoSizeVariant]
}

struct PhotoSizeVariant: Equatable, Codable {
    var webp: ImageLocation
    var width: Int
    var height: Int
}

struct VideoAttachment: Equatable {

}

extension PhotoAttachment {
    var aspectRatio: Double {
        sizes.first.map { Double($0.width) / Double($0.height) } ?? 1
    }
}
