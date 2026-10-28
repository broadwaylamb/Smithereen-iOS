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

    func totalRepostOffset(postKind: PostKind) -> CGFloat {
        switch postKind {
        case .regular:
            0
        case .repost(let repostInfo):
            CGFloat(repostInfo.level + 1) * singleRepostOffset
        }
    }

    var detailButtonSize: CGSize {
        CGSize(width: 32, height: 32)
    }

    var repostVerticalLineThickness: CGFloat { 2 }
}
