import SwiftUI
import SmithereenAPI

struct PostTextView: View {
    var blocks: [RichText.Block]
    var isSelectable: Bool = false

    var body: some View {
        if blocks.isEmpty {
            EmptyView()
        } else {
            PostTextViewAdapter(blocks: blocks, isSelectable: isSelectable)
                .debugBorder()
        }
    }
}

// NOTE: This used to be a pure SwiftUI view, but SwiftUI has HUGE performance
// issues with large texts. Also, as of January 2026, SwiftUI Text doesn't allow proper
// text selection (you can only select the whole thing, but not parts of the text).
//
// For this reason, it has been rewritten with UIKit.
private struct PostTextViewAdapter: UIViewRepresentable {
    var blocks: [RichText.Block]
    var isSelectable: Bool

    private static let defaultBodyFont = UIFont
        .preferredFont(
            forTextStyle: .body,
            compatibleWith: UITraitCollection(preferredContentSizeCategory: .large)
        )

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

    func makeUIView(context: Context) -> PostUITextView {
        return PostUITextView(frame: .zero, textContainer: nil)
    }

    func updateUIView(_ textView: PostUITextView, context: Context) {
        let attrStr = AttributedString(
            blocks,
            sizeAttributes: SizeAttributes(
                baseFontSize: baseFontSize,
                subscriptBaselineOffset: subscriptBaselineOffset,
                superscriptBaselineOffset: superscriptBaselineOffset,
            ),
            depth: 0,
        )
        textView.isSelectable = isSelectable
        textView.attributedText = NSAttributedString(attrStr)
    }

    @available(iOS 16.0, *)
    func sizeThatFits(
        _ proposal: ProposedViewSize,
        uiView textView: PostUITextView,
        context: Context,
    ) -> CGSize? {
        textView.sizeThatFits(
            proposal.replacingUnspecifiedDimensions(
                by: CGSize(width: CGFloat.infinity, height: .infinity)
            )
        )
    }
}

private final class PostUITextView: UITextView {
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        self.textContainer.lineBreakMode = .byWordWrapping
        self.textContainer.lineFragmentPadding = 0
        isEditable = false
        isScrollEnabled = false
        textContainerInset = .zero
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not implemented")
    }

    override var intrinsicContentSize: CGSize {
        return UIView.layoutFittingCompressedSize
    }
}

extension PostTextView {
    init(_ postText: RichText) {
        blocks = postText.blocks
    }
}

private struct QuoteView: View {
    var blocks: [RichText.Block]

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

// https://en.wikipedia.org/wiki/Subscript_and_superscript#HTML
private let subscriptFontSizeMultiplier: CGFloat = 0.75

private struct SizeAttributes {
    var baseFontSize: CGFloat
    var subscriptBaselineOffset: CGFloat
    var superscriptBaselineOffset: CGFloat
}

extension AttributedString {
    // A workaround for "Conformance of 'NSParagraphStyle' to 'Sendable' is unavailable"
    // https://forums.swift.org/t/how-to-disable-sendable-check-to-a-setter/66876
    fileprivate mutating func setParagraphStyle(_ style: NSParagraphStyle) {
        mergeAttributes(AttributeContainer([.paragraphStyle : style]))
    }
}

extension AttributedString {
    fileprivate init(
        _ blocks: [RichText.Block],
        sizeAttributes: SizeAttributes,
        depth: Int,
    ) {
        self.init()
        var isFirst = true
        for block in blocks {
            if isFirst {
                isFirst = false
            } else {
                self += "\n\r"
            }
            self += AttributedString(block, sizeAttributes: sizeAttributes, depth: depth)
        }
    }

    fileprivate init(_ block: RichText.Block, sizeAttributes: SizeAttributes, depth: Int) {
        switch block {
        case .paragraph(let nodes):
            self.init(nodes, sizeAttributes: sizeAttributes)
            let paragraphStyle = NSMutableParagraphStyle()
            var fontContainer = AttributeContainer()
            fontContainer.uiKit.font = .systemFont(ofSize: sizeAttributes.baseFontSize)
            setParagraphStyle(paragraphStyle)
            mergeAttributes(fontContainer, mergePolicy: .keepCurrent)
        case .quote(let children):
            self.init(children, sizeAttributes: sizeAttributes, depth: depth + 1)
            // TODO
        case .codeBlock(let code):
            var attributes = AttributeContainer()
            attributes.uiKit.font = .monospacedSystemFont(
                ofSize: sizeAttributes.baseFontSize,
                weight: .regular,
            )
            self.init(code, attributes: attributes)
            let paragraphStyle = NSMutableParagraphStyle()
            setParagraphStyle(paragraphStyle)
        }
    }

    fileprivate init(_ nodes: [RichText.InlineNode], sizeAttributes: SizeAttributes) {
        self.init()
        func recurse(
            _ nodes: [RichText.InlineNode],
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
                    if newAttributes.inlinePresentationIntent?.contains(.emphasized) == true {
                        // UIKit doesn't handle bold italics natively
                        newAttributes.setBoldItalic(sizeAttributes: sizeAttributes)
                    }
                    recurse(
                        children,
                        attributes: newAttributes,
                        subscriptDepth: subscriptDepth,
                    )
                case .emphasis(let children):
                    newAttributes.inlinePresentationIntent.insert(.emphasized)
                    if newAttributes.inlinePresentationIntent?.contains(.stronglyEmphasized) == true {
                        // UIKit doesn't handle bold italics natively
                        newAttributes.setBoldItalic(sizeAttributes: sizeAttributes)
                    }
                    recurse(
                        children,
                        attributes: newAttributes,
                        subscriptDepth: subscriptDepth,
                    )
                case .underline(let children):
                    newAttributes.uiKit.underlineStyle = .single
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
                            sizeAttributes.subscriptBaselineOffset
                        } else {
                            sizeAttributes.superscriptBaselineOffset
                        }
                    let m = subscriptFontSizeMultiplier
                    newAttributes.uiKit.baselineOffset =
                        currentBaselineOffset + baselineOffset * pow(m, CGFloat(subscriptDepth))
                    newAttributes.uiKit.font =
                        .systemFont(ofSize: sizeAttributes.baseFontSize * pow(m, CGFloat(subscriptDepth + 1)))
                    recurse(
                        children,
                        attributes: newAttributes,
                        subscriptDepth: subscriptDepth + 1,
                    )
                case .link(let url, _, let children):
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

extension AttributeContainer {
    fileprivate mutating func setBoldItalic(sizeAttributes: SizeAttributes) {
        let font = self.uiKit.font
            ?? UIFont.systemFont(ofSize: sizeAttributes.baseFontSize)
        guard let newFontDescriptor = font
                .fontDescriptor
                .withSymbolicTraits([.traitBold, .traitItalic])
        else {
            return
        }
        self.uiKit.font = UIFont(descriptor: newFontDescriptor, size: font.pointSize)
    }
}


@available(iOS 17.0, *)
#Preview("Basic", traits: .sizeThatFitsLayout) {
    PostTextView(
        RichText(
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
    .debugBorder()
    .padding(8)
    .environmentObject(PaletteHolder())
}

#Preview {
    List {
        PostTextView(
            RichText(html: """
                <p>
                Custom views typically have content that they display of which the layout system is unaware. Setting this property allows a custom view to communicate to the layout system what size it would like to be based on its content. This intrinsic size must be independent of the content frame, because there’s no way to dynamically communicate a changed width to the layout system based on a changed height, for example.
                </p>
                """)
        )
    }
}
