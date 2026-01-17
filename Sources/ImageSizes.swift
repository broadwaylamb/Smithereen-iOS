import SmithereenAPI
import UIKit

struct ImageSizes {
    fileprivate var sizes: [(CGSize, URL)] = []

    var aspectRatio: CGFloat {
        sizes.last?.0.aspectRatio ?? 1
    }

    mutating func append(size: CGFloat, url: URL?) {
        append(size: CGSize(width: size, height: size), url: url)
    }

    mutating func append(size: CGSize, url: URL?) {
        if let url {
            sizes.append((size, url))
        }
    }

    func sizeThatFits(_ size: CGSize, scale: CGFloat) -> ImageLocation? {
        return sizeThatFits(width: size.width, height: size.height, scale: scale)
    }

    func sizeThatFits(width: CGFloat, height: CGFloat, scale: CGFloat) -> ImageLocation? {
        let proposedAspectRatio = width / height

        for (size, url) in sizes {
            if proposedAspectRatio > size.aspectRatio && size.width >= width * scale {
                return ImageLocation(url: url)
            }
            if proposedAspectRatio < size.aspectRatio && size.height >= height * scale {
                return ImageLocation(url: url)
            }
        }
        return sizes.last.map { (_ , url) in ImageLocation(url: url) }
    }

    func sizeThatFits(square: CGFloat, scale: CGFloat) -> ImageLocation? {
        sizeThatFits(width: square, height: square, scale: scale)
    }
}

extension Photo {
    var imageSizes: ImageSizes {
        ImageSizes(
            sizes: sizes.map {
                (CGSize(width: $0.width, height: $0.height), $0.url)
            }
        )
    }
}
