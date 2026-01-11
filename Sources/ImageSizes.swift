import Foundation
import SmithereenAPI

struct ImageSizes {
    fileprivate var sizes: [(CGFloat, URL)] = []

    mutating func append(size: CGFloat, url: URL?) {
        if let url {
            sizes.append((size, url))
        }
    }

    func sizeThatFits(width: CGFloat, height: CGFloat) -> ImageLocation? {
        let minSide = min(width, height)
        for (side, url) in sizes {
            if minSide < side {
                return ImageLocation(url: url)
            }
        }
        return nil
    }

    func sizeThatFits(square: CGFloat) -> ImageLocation? {
        sizeThatFits(width: square, height: square)
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
