import UIKit

struct PostViewMetrics {
    var horizontalSizeClass: UIUserInterfaceSizeClass

    var horizontalInset: CGFloat {
        horizontalSizeClass == .regular ? 13 : 8
    }

    var topInset: CGFloat {
        horizontalSizeClass == .regular ? 13 : 7
    }

    var singleRepostOffset: CGFloat {
        horizontalSizeClass == .regular ? 13 : 0
    }

    private func totalRepostOffset(level: Int) -> CGFloat {
        CGFloat(level) * singleRepostOffset
    }

    func totalRepostOffset(postKind: PostKind) -> CGFloat {
        let level = switch postKind {
        case .regular:
            0
        case .repost(let repostInfo):
            repostInfo.level + 1
        }
        return totalRepostOffset(level: level)
    }

    func textWidth(baseWidth: CGFloat, repostLevel: Int) -> CGFloat {
        baseWidth - horizontalInset * 2 - totalRepostOffset(level: repostLevel)
    }

    var detailButtonSize: CGSize {
        CGSize(width: 32, height: 32)
    }

    var repostVerticalLineThickness: CGFloat { 2 }
}
