import SwiftUI

struct Icons {
    private static func icon(
        _ layoutDirection: LayoutDirection,
        iOS17Name: String,
        ltrName: String,
        rtlName: String,
    ) -> Image {
        if #available(iOS 17.0, *) {
            return Image(systemName: iOS17Name)
        }
        switch layoutDirection {
        case .leftToRight:
            return Image(systemName: ltrName)
        case .rightToLeft:
            return Image(systemName: rtlName)
        @unknown default:
            return Image(systemName: iOS17Name)
        }
    }

    static func comment(_ layoutDirection: LayoutDirection) -> Image {
        icon(layoutDirection,
             iOS17Name: "bubble.fill",
             ltrName: "bubble.left.fill",
             rtlName: "bubble.right.fill"
        )
    }

    static func like() -> Image {
        Image(systemName: "heart.fill")
    }
}
