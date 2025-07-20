import SwiftSoup
import SwiftUI

struct PostTextView: View {
    var blocks: [PostTextBlock]

    private static let defaultBodyFont = UIFont
        .preferredFont(
            forTextStyle: .body,
            compatibleWith: UITraitCollection(preferredContentSizeCategory: .large)
        )

    // https://en.wikipedia.org/wiki/Subscript_and_superscript#HTML
    fileprivate static let subscriptFontSizeMultiplier: CGFloat = 0.75

    @ScaledMetric(relativeTo: .body)
    private var paragraphSpacing = 8

    @ScaledMetric(relativeTo: .body)
    private var baseFontSize = defaultBodyFont.pointSize

    @ScaledMetric(relativeTo: .body)
    private var subscriptBaselineOffset: CGFloat =
        -defaultBodyFont.capHeight * subscriptFontSizeMultiplier / 2

    @ScaledMetric(relativeTo: .body)
    private var superscriptBaselineOffset: CGFloat =
        defaultBodyFont.capHeight * (1 - subscriptFontSizeMultiplier / 2)

    @ViewBuilder
    private func renderBlock(_ block: PostTextBlock) -> some View {
        switch block {
        case .paragraph(let content):
            Text(
                AttributedString(
                    content,
                    baseFontSize: baseFontSize,
                    subscriptBaselineOffset: subscriptBaselineOffset,
                    superscriptBaselineOffset: superscriptBaselineOffset,
                )
            )
            .fixedSize(horizontal: false, vertical: true)
        case .quote(let children):
            QuoteView(blocks: children)
                .fixedSize(horizontal: false, vertical: true)
        case .codeBlock(let content):
            CodeBlockView(code: content)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    var body: some View {
        switch blocks.count {
        case 0:
            EmptyView()
        case 1:
            renderBlock(blocks[0])
        default:
            VStack(alignment: .leading, spacing: paragraphSpacing) {
                ForEach(blocks.indexed(), id: \.offset) {
                    renderBlock($0.element)
                }
            }
        }
    }
}

extension PostTextView {
    init(_ postText: PostText) {
        blocks = postText.blocks
    }
}

private struct QuoteView: View {
    var blocks: [PostTextBlock]

    @ScaledMetric(relativeTo: .body) private var verticalLineThickness = 2
    @ScaledMetric(relativeTo: .body) private var verticalTextPadding = 2
    @ScaledMetric(relativeTo: .body) private var leadingTextPadding = 8

    var body: some View {
        HStack(spacing: 0) {
            Color.accentColor
                .opacity(0.5)
                .frame(maxWidth: verticalLineThickness)
            PostTextView(blocks: blocks)
                .padding(.vertical, verticalTextPadding)
                .padding(.leading, leadingTextPadding)
        }
    }
}

private struct CodeBlockView: View {
    var code: String

    @EnvironmentObject private var palette: PaletteHolder
    @ScaledMetric(relativeTo: .body) private var codePadding = 8

    var body: some View {
        Text(code)
            .font(.body.monospaced())
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding(codePadding)
            .background(palette.postCodeBlockBackground)
            .clipShape(RoundedRectangle(cornerRadius: 2))
    }
}

extension AttributedString {
    @MainActor
    init(
        _ nodes: [PostTextInlineNode],
        baseFontSize: CGFloat,
        subscriptBaselineOffset: CGFloat,
        superscriptBaselineOffset: CGFloat,
    ) {
        self.init()
        func recurse(
            _ nodes: [PostTextInlineNode],
            attributes: AttributeContainer,
            subscriptDepth: Int,
        ) {
            for node in nodes {
                var newAttributes = attributes
                switch node {
                case .text(let s):
                    self += AttributedString(s, attributes: attributes)
                case .lineBreak:
                    self += AttributedString("\n", attributes: attributes)
                case .code(let children):
                    newAttributes.inlinePresentationIntent.insert(.code)
                    recurse(
                        children,
                        attributes: newAttributes,
                        subscriptDepth: subscriptDepth,
                    )
                case .strong(let children):
                    newAttributes.inlinePresentationIntent.insert(.stronglyEmphasized)
                    recurse(
                        children,
                        attributes: newAttributes,
                        subscriptDepth: subscriptDepth,
                    )
                case .emphasis(let children):
                    newAttributes.inlinePresentationIntent.insert(.emphasized)
                    recurse(
                        children,
                        attributes: newAttributes,
                        subscriptDepth: subscriptDepth,
                    )
                case .underline(let children):
                    newAttributes.underlineStyle = .single
                    recurse(
                        children,
                        attributes: newAttributes,
                        subscriptDepth: subscriptDepth,
                    )
                case .strikethrough(let children):
                    newAttributes.inlinePresentationIntent.insert(.strikethrough)
                    recurse(
                        children,
                        attributes: newAttributes,
                        subscriptDepth: subscriptDepth,
                    )
                case .subscript(let children), .superscript(let children):
                    let currentBaselineOffset = attributes.baselineOffset ?? 0
                    let baselineOffset =
                        if case .subscript = node {
                            subscriptBaselineOffset
                        } else {
                            superscriptBaselineOffset
                        }
                    let m = PostTextView.subscriptFontSizeMultiplier
                    newAttributes.baselineOffset =
                        currentBaselineOffset + baselineOffset
                        * pow(m, CGFloat(subscriptDepth))
                    newAttributes.font =
                        .system(size: baseFontSize * pow(m, CGFloat(subscriptDepth + 1)))
                    recurse(
                        children,
                        attributes: newAttributes,
                        subscriptDepth: subscriptDepth + 1,
                    )
                case .link(let url, let children):
                    var newAttributes = attributes
                    newAttributes.link = url
                    recurse(
                        children,
                        attributes: newAttributes,
                        subscriptDepth: subscriptDepth,
                    )
                }
            }
        }
        recurse(nodes, attributes: AttributeContainer(), subscriptDepth: 0)
    }
}

@available(iOS 17.0, *)
#Preview("Basic", traits: .sizeThatFitsLayout) {
    PostTextView(
        try! PostText(
            html: """
            <p>
                First paragraph, with <b>bold</b>, <i>italic</i>, <u>underlined</u>,
                <s>strikethrough</s> and <code>monospace</code> text.
                <br>
                Subscripts and superscripts are also supported:
                C<sub>12</sub>H<sub>22</sub>O<sub>11</sub>, χ<sup>2</sup>.
                <br>
                ps<sub>ps<sub>ps<sub>ps<sub>ps<sub>ps<sub>ps<sub>ps
                <sub>ps<sub>ps<sub>ps<sub>ps<sub>ps<sub>ps
                </sub></sub></sub></sub></sub></sub></sub></sub></sub></sub></sub></sub></sub>
                <br>
                ps<sup>ps<sup>ps<sup>ps<sup>ps<sup>ps<sup>ps<sup>ps
                <sup>ps<sup>ps<sup>ps<sup>ps<sup>ps<sup>ps
                </sup></sup></sup></sup></sup></sup></sup></sup></sup></sup></sup></sup></sup>
                <br>
                ps<sub>ps<sup>ps<sub>ps<sup>ps<sub>ps<sup>ps<sub>ps
                <sup>ps<sub>ps<sup>ps<sub>ps<sup>ps<sub>ps<sup>ps</sup></sub>
                </sup></sub></sup></sub></sup></sub></sup></sub></sup></sub></sup></sub>
                <br>
                <a href="http://example.com">Links</a> are supported too.
            </p>
            <p>
                Second paragraph. <b><i>Bold italic</i></b>,
                <u><s>underlined strikethrogh</s></u>.
            </p>
            <blockquote>
                <p>
                    First paragraph of a quote.
                </p>
                <p>
                    Second paragraph of a quote.
                </p>
                <blockquote>
                    <p>
                        Nested quote
                    </p>
                </blockquote>
                <p>
                    The rest of the quote.
                </p>
            </blockquote>
            <pre>Some code block. Words are wrapped if it's very loooooooooooooong.
            <pre>
            Nested code blocks are not allowed.</pre></pre>
            <pre>func main() {
                print("Hello, world!")
            }</pre>
            """
        )
    )
    .padding(8)
}
