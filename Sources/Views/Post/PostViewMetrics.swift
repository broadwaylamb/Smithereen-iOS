import UIKit

struct PostViewMetrics {
    var traitCollection: UITraitCollection

    var horizontalInset: CGFloat {
        traitCollection.horizontalSizeClass == .regular ? 13 : 8
    }

    var topInset: CGFloat {
        traitCollection.horizontalSizeClass == .regular ? 13 : 7
    }

    var singleRepostOffset: CGFloat {
        traitCollection.horizontalSizeClass == .regular ? 13 : 0
    }

    func totalRepostOffset(postKind: PostKind) -> CGFloat {
        let level = switch postKind {
        case .regular:
            0
        case .repost(let repostInfo):
            repostInfo.level + 1
        }
        return CGFloat(level) * singleRepostOffset
    }

    func textLeadingOffset(
        postKind: PostKind,
        quoteLevel: Int,
    ) -> CGFloat {
        horizontalInset
            + totalRepostOffset(postKind: postKind)
            + CGFloat(quoteLevel) * (verticalLineThickness + quoteOffsetFromVerticalLine)
    }

    func availableTextWidth(
        baseWidth: CGFloat,
        postKind: PostKind,
        quoteLevel: Int,
    ) -> CGFloat {
        baseWidth
            - textLeadingOffset(postKind: postKind, quoteLevel: quoteLevel)
            - horizontalInset
    }

    var detailButtonSize: CGSize {
        CGSize(width: 32, height: 32)
    }

    var verticalLineThickness: CGFloat { 2 }

    var quoteOffsetFromVerticalLine: CGFloat { 8 }

    var codeBlockPadding: CGFloat { 8 }

    var paragraphSpacing: CGFloat {
        let fontMetrics = UIFontMetrics(forTextStyle: .body)
        return fontMetrics.scaledValue(for: 8, compatibleWith: traitCollection)
    }
}
