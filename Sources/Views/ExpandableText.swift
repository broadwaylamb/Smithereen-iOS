import SwiftUI

// https://www.fivestars.blog/articles/trucated-text/
struct ExpandableText: View {
    var text: AttributedString
    var lineLimit: Int?

    @AppStorage(.palette) private var palette: Palette = .smithereen

    @State private var isExpanded: Bool = false
    @State private var intrinsicHeight: CGFloat = 0
    @State private var truncatedHeight: CGFloat = 0

    init(_ text: AttributedString, lineLimit: Int?) {
        self.text = text
        self.lineLimit = lineLimit
    }

    private var textView: Text {
        Text(text)
    }

    private var expandTextButton: some View {
        Button(action: { isExpanded.toggle() }) {
            Text("Expand text…")
                .foregroundStyle(palette.accent)
        }
    }

    @ViewBuilder
    private func makeStack(lineLimit: Int, isCollapsed: () -> Bool) -> some View {
        VStack(alignment: .leading) {
            if isCollapsed() {
                textView
                    .lineLimit(lineLimit)
                expandTextButton
            } else {
                textView
            }
        }
    }

    var body: some View {
        if let lineLimit = self.lineLimit {
            makeStack(lineLimit: lineLimit, isCollapsed: { intrinsicHeight > truncatedHeight && !isExpanded })
                .background {
                    makeStack(lineLimit: lineLimit, isCollapsed: { true })
                        .fixedSize(horizontal: false, vertical: true)
                        .hidden()
                        .readSize {
                            truncatedHeight = $0.height
                        }
                    makeStack(lineLimit: lineLimit, isCollapsed: { false })
                        .fixedSize(horizontal: false, vertical: true)
                        .hidden()
                        .readSize {
                            intrinsicHeight = $0.height
                        }
                }
        } else {
            textView
        }
    }
}

@available(iOS 17.0, *)
#Preview("ExpandableText is truncated", traits: .sizeThatFitsLayout) {
    ExpandableText(
        """
        Lorem ipsum dolor sit amet, consectetur adipiscing elit, \
        sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. \
        Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris \
        nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in \
        reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla \
        pariatur. Excepteur sint occaecat cupidatat non proident, sunt in \
        culpa qui officia deserunt mollit anim id est laborum.
        """,
        lineLimit: 3,
    )
    .prefireIgnored()
}

@available(iOS 17.0, *)
#Preview("ExpandableText is fully displayed", traits: .sizeThatFitsLayout) {
    ExpandableText(
        """
        Hello, World!
        """,
        lineLimit: 3,
    )
    .prefireIgnored()
}


@available(iOS 17.0, *)
#Preview("ExpandText is one line longer than the line limit", traits: .fixedLayout(width: 320, height: 200)) {
    ExpandableText(
        """
        Lorem ipsum dolor sit amet, 
        consectetur adipiscing elit,
        sed do eiusmod tempor
        incididunt ut labore et dolore magna aliqua.
        Ut enim ad minim veniam,
        """,
        lineLimit: 4,
    )
    .dynamicTypeSize(.medium)
    .prefireIgnored()
}
