import Combine
import UIKit

private let defaultBodyFont = UIFont
    .preferredFont(
        forTextStyle: .body,
        compatibleWith: UITraitCollection(preferredContentSizeCategory: .large)
    )

final class PostTextBlockView: UIView, @MainActor ContentView {
    struct Configuration: @MainActor UIContentConfiguration {
        var palette: PaletteHolder
        var postKind: PostKind
        var block: RichText.FlattenedBlock
        var previousItem: PostViewModel.DisplayItem
        var text: AttributedString

        // https://en.wikipedia.org/wiki/Subscript_and_superscript#HTML
        fileprivate static let subscriptFontSizeMultiplier: CGFloat = 0.75

        init(
            postKind: PostKind,
            block: RichText.FlattenedBlock,
            previousItem: PostViewModel.DisplayItem,
            palette: PaletteHolder,
            traitCollection: UITraitCollection,
        ) {
            self.postKind = postKind
            self.block = block
            self.previousItem = previousItem
            self.palette = palette

            // TODO: Move this work off the main thread, cache rendered text?
            let fontMetrics = UIFontMetrics(forTextStyle: .body)
            let defaultCapHeight = defaultBodyFont.capHeight
            let baseFontSize = fontMetrics.scaledValue(
                for: defaultBodyFont.pointSize,
                compatibleWith: traitCollection
            )
            self.text = AttributedString(
                block.content,
                baseFontSize: baseFontSize,
                subscriptBaselineOffset: fontMetrics.scaledValue(
                    for: -defaultCapHeight * Self.subscriptFontSizeMultiplier / 2,
                    compatibleWith: traitCollection
                ),
                superscriptBaselineOffset: fontMetrics.scaledValue(
                    for: defaultCapHeight * (1 - Self.subscriptFontSizeMultiplier / 2),
                    compatibleWith: traitCollection,
                )
            )
            let font: UIFont = block.isCodeBlock
                ? .monospacedSystemFont(ofSize: baseFontSize, weight: .regular)
                : .systemFont(ofSize: baseFontSize)
            text.mergeAttributes(AttributeContainer().font(font))
        }

        func makeContentView() -> any UIView & UIContentView {
            PostTextBlockView(configuration: self)
        }
        
        func updated(for state: any UIConfigurationState) -> Configuration {
            Configuration(
                postKind: postKind,
                block: block,
                previousItem: previousItem,
                palette: palette,
                traitCollection: state.traitCollection,
            )
        }
    }

    var configuration: Configuration {
        didSet {
            configurationDidChange()
        }
    }

    private let codeBlockScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.layer.cornerRadius = 2
        return scrollView
    }()

    private let textView: UITextView = {
        let textView = UITextView()
        textView.isScrollEnabled = false
        textView.isEditable = false
        textView.isSelectable = false
        textView.backgroundColor = .clear
        return textView
    }()

    private var contentView: UIView {
        if configuration.block.isCodeBlock {
            codeBlockScrollView
        } else {
            textView
        }
    }

    private var paletteSubscription: AnyCancellable?

    init(configuration: Configuration) {
        self.configuration = configuration
        super.init(frame: .zero)
        isOpaque = false
        configurationDidChange()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var textContainerInset: UIEdgeInsets {
        if configuration.block.isCodeBlock {
            let value = UIFontMetrics(forTextStyle: .body)
                .scaledValue(for: 8, compatibleWith: traitCollection)
            return UIEdgeInsets(top: value, left: value, bottom: value, right: value)
        } else {
            return .zero
        }
    }

    private func configurationDidChange() {
        paletteSubscription = configuration.palette.$palette
            .sink { [weak self] palette in
                self?.paletteDidUpdate(palette)
            }
        let isCodeBlock = configuration.block.isCodeBlock
        textView.attributedText = NSAttributedString(configuration.text)
        textView.textContainer.lineFragmentPadding = 0
        if isCodeBlock {
            codeBlockScrollView.addSubview(textView)
            addSubview(codeBlockScrollView)
            codeBlockScrollView.backgroundColor =
                configuration.palette.$postCodeBlockBackground.uiColor
            let inset = UIFontMetrics(forTextStyle: .body)
                .scaledValue(for: 8, compatibleWith: traitCollection)
            textView.textContainerInset =
                UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)
        } else {
            codeBlockScrollView.removeFromSuperview()
            addSubview(textView)
            textView.textContainerInset = .zero
        }
        textView.textContainerInset = textContainerInset
        setNeedsDisplay()
    }

    private func paletteDidUpdate(_ palette: Palette) {
        setNeedsDisplay()
    }

    private var metrics: PostViewMetrics {
        PostViewMetrics(traitCollection: traitCollection)
    }

    private func contentViewSize(proposedWidth: CGFloat) -> CGSize {
        let metrics = self.metrics
        let availableWidth = metrics.availableTextWidth(
            baseWidth: proposedWidth,
            postKind: configuration.postKind,
            quoteLevel: configuration.block.quoteLevel,
        )
        let textHeight = if configuration.block.isCodeBlock {
            textView
                .sizeThatFits(width: .greatestFiniteMagnitude)
                .height
        } else {
            textView.sizeThatFits(width: availableWidth).height
        }
        return CGSize(width: availableWidth, height: textHeight)
    }

    private var textViewLeadingOffset: CGFloat {
        metrics.textLeadingOffset(
            postKind: configuration.postKind,
            quoteLevel: configuration.block.quoteLevel,
        )
    }

    private var topOffset: CGFloat {
        if case .header = configuration.previousItem {
            13
        } else {
            metrics.paragraphSpacing
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let contentFrame = CGRect(
            origin: CGPoint(x: textViewLeadingOffset, y: topOffset),
            size: contentViewSize(proposedWidth: bounds.width),
        )
        if configuration.block.isCodeBlock {
            codeBlockScrollView.frame = contentFrame
            textView.frame.origin = .zero
            textView.frame.size = textView.sizeThatFits(width: .greatestFiniteMagnitude)
            codeBlockScrollView.contentSize = textView.frame.size
        } else {
            textView.frame = contentFrame
        }
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        CGSize(
            width: size.width,
            height: topOffset + contentViewSize(proposedWidth: size.width).height,
        )
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        drawRepostVerticalLines(
            postKind: configuration.postKind,
            topInset: 0,
            palette: configuration.palette.palette,
            traitCollection: traitCollection,
        )

        let quoteLevel = configuration.block.quoteLevel
        if quoteLevel > 0, let context = UIGraphicsGetCurrentContext() {
            let metrics = self.metrics
            let lineThickness = metrics.verticalLineThickness
            context.setStrokeColor(configuration.palette.$accent.withAlpha(0.5).cgColor)
            context.setLineWidth(lineThickness)
            let start = metrics.textLeadingOffset(
                postKind: configuration.postKind,
                quoteLevel: 0,
            )
            let singleQuoteOffset = metrics.quoteOffsetFromVerticalLine
            for level in 0..<quoteLevel {
                context.beginPath()
                let offset = start
                    + lineThickness / 2
                    + CGFloat(level) * (lineThickness + singleQuoteOffset)
                let y: CGFloat = switch configuration.previousItem {
                case .header:
                    13
                case .textBlock(_, let flattenedBlock)
                    where flattenedBlock.quoteLevel >= level + 1:
                    0
                default:
                    metrics.paragraphSpacing
                }
                context.addLines(
                    between: [
                        CGPoint(x: offset, y: y),
                        CGPoint(x: offset, y: bounds.height)
                    ]
                )
                context.strokePath()
            }
        }
    }
}
