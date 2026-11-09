import StyledTextKit
import UIKit

struct TextRenderingParameters {
    var contentSizeCategory: UIContentSizeCategory
    var displayScale: CGFloat
    var width: (_ repostLevel: Int) -> CGFloat
    var maximumNumberOfLines: Int = 0
}

extension StyledTextRenderer {
    static func createAndWarmCaches(
        _ string: StyledTextString,
        parameters: TextRenderingParameters,
        repostLevel: Int
    ) -> StyledTextRenderer {
        StyledTextRenderer(
            string: string,
            contentSizeCategory: parameters.contentSizeCategory,
            scale: parameters.displayScale,
            maximumNumberOfLines: parameters.maximumNumberOfLines,
        )
        .warm(.bitmap, width: parameters.width(repostLevel))
    }
}

