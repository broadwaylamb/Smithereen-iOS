import SmithereenAPI
import UIKit

struct ImageSizes {
    fileprivate var sizes: [(CGFloat, URL)] = []

    mutating func append(size: CGFloat, url: URL?) {
        if let url {
            sizes.append((size, url))
        }
    }

    func sizeThatFits(_ size: CGSize, scale: CGFloat) -> ImageLocation? {
        return sizeThatFits(width: size.width, height: size.height, scale: scale)
    }

    func sizeThatFits(width: CGFloat, height: CGFloat, scale: CGFloat) -> ImageLocation? {
        let minSide = min(width, height) * scale
        for (side, url) in sizes {
            if minSide < side {
                return ImageLocation(url: url)
            }
        }
        return sizes.last.map { (_ , url) in ImageLocation(url: url) }
    }

    func sizeThatFits(square: CGFloat, scale: CGFloat) -> ImageLocation? {
        sizeThatFits(width: square, height: square, scale: scale)
    }
}

extension Group {
    var squareProfilePictureSizes: ImageSizes {
        var sizes = ImageSizes()
        if let url = photo50 {
            sizes.sizes.append((50, url))
        }
        if let url = photo100 {
            sizes.sizes.append((100, url))
        }
        if let url = photo200 {
            sizes.sizes.append((200, url))
        }
        if let url = photo400 {
            sizes.sizes.append((400, url))
        }
        if let url = photoMax {
            sizes.sizes.append((.infinity, url))
        }
        return sizes
    }
}

extension Photo {
    var imageSizes: ImageSizes {
        ImageSizes(
            sizes: sizes.map {
                (CGFloat($0.type.maxSize), $0.url)
            }
        )
    }
}
