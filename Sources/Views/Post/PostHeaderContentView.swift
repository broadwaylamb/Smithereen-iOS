import UIKit
import SmithereenAPI
import Combine

@MainActor
struct PostHeaderContentConfiguration: @MainActor UIContentConfiguration {
    var viewModel: PostViewModel
    var postKind: PostKind
    var palette: PaletteHolder
    var pushToNavigationStack: ((any Hashable) -> ())?

    var repostID: WallPostID? {
        switch postKind {
        case .regular:
            nil
        case .repost(let repostInfo):
            repostInfo.repostedPostID
        }
    }

    var hasDetailsButton: Bool {
        postKind == .regular
    }

    var author: PostAuthor {
        viewModel.getAuthor(repostID)
    }

    func makeContentView() -> any UIView & UIContentView {
        return PostHeaderContentView(configuration: self)
    }

    func updated(for state: any UIConfigurationState) -> PostHeaderContentConfiguration {
        self
    }
}


final class PostHeaderContentView: UIView, @MainActor ContentView {
    var configuration: PostHeaderContentConfiguration {
        didSet {
            configurationDidChange()
            setNeedsLayout()
        }
    }

    private let profilePictureButton = {
        var config = UIButton.Configuration.plain()
        config.contentInsets = .zero
        config.background.cornerRadius = 0
        let button = UIButton(configuration: config)
        button.layer.borderWidth = 1
        return button
    }()

    private static func makeTextButton(_ block: (UIButton, UILabel) -> Void) -> UIButton {
        var config = UIButton.Configuration.plain()
        config.titleAlignment = .leading
        config.contentInsets = .zero
        config.cornerStyle = .fixed
        config.background.cornerRadius = 0
        let button = UIButton(configuration: config)
        button.contentHorizontalAlignment = .leading
        let label = button.titleLabel!
        label.adjustsFontForContentSizeCategory = true
        block(button, label)
        return button
    }

    private let authorNameButton = makeTextButton { button, label in
        label.numberOfLines = 2
        button.configuration!.titleTextAttributesTransformer =
            UIConfigurationTextAttributesTransformer { attrs in
                var attrs = attrs
                let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body)
                let font = UIFont.boldSystemFont(ofSize: descriptor.pointSize)
                let metrics = UIFontMetrics(forTextStyle: .body)
                attrs.uiKit.font = metrics.scaledFont(for: font)
                return attrs
            }
        button.layer.borderWidth = 1 // TOOD: Remove
    }

    private let grayTextButton = makeTextButton { button, label in
        button.configuration!.titleTextAttributesTransformer =
            UIConfigurationTextAttributesTransformer { attrs in
                var attrs = attrs
                attrs.uiKit.font = UIFont.preferredFont(forTextStyle: .caption1)
                return attrs
            }
    }

    private static let detailsImage = UIImage.ellipsis
    private static let mastodonRepostImage = UIImage.repostHeaderMastodonStyle
    private static let quoteRepostImage = UIImage.repostHeaderQuote

    private let detailsButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.image = detailsImage
        config.background.cornerRadius = 0
        let button = UIButton(configuration: config)
        return button
    }()

    init(configuration: PostHeaderContentConfiguration) {
        self.configuration = configuration
        super.init(frame: .zero)
        isOpaque = false
        addSubview(profilePictureButton)
        addSubview(authorNameButton)
        addSubview(grayTextButton)
        paletteDidUpdate(configuration.palette.palette)
        configurationDidChange()
        authorNameButton
            .addTarget(self, action: #selector(navigateToPostAuthor), for: .touchUpInside)
        profilePictureButton
            .addTarget(self, action: #selector(navigateToPostAuthor), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var imageSize: CGFloat {
        let isWide = traitCollection.horizontalSizeClass == .regular
        let baseSize: CGFloat =
            switch configuration.postKind {
            case .regular:
                isWide ? 55 : 40
            case .repost:
                isWide ? 50 : 32
            }
        return UIFontMetrics(forTextStyle: .body).scaledValue(for: baseSize)
    }

    private var paletteSubscription: AnyCancellable?

    private func addOrRemoveSubview(_ subview: UIView, if condition: Bool) {
        if condition {
            if subview.superview == nil {
                addSubview(subview)
            }
        } else {
            subview.removeFromSuperview()
        }
    }

    private func updateAuthorName(_ palette: Palette) {
        let authorName = configuration.author.displayedName

        switch configuration.postKind {
        case .regular:
            authorNameButton.setAttributedTitle(nil, for: .normal)
            authorNameButton.setTitle(authorName, for: .normal)
        case .repost(let repostInfo):
            let image = repostInfo.isMastodonStyle
                ? Self.mastodonRepostImage
                : Self.quoteRepostImage
            let attachment = NSTextAttachment(
                image: image.withTintColor(palette.$repostIcon.uiColor)
            )
            let repostIconSize = UIFontMetrics(forTextStyle: .body).scaledValue(for: 13)
            attachment.bounds.size = CGSize(width: repostIconSize, height: repostIconSize)
            let title = NSMutableAttributedString(attachment: attachment)
            title.append(NSAttributedString(string: " " + authorName))
            authorNameButton.setTitle(nil, for: .normal)
            authorNameButton.setAttributedTitle(title, for: .normal)
        }
    }

    private func configurationDidChange() {
        updateAuthorName(configuration.palette.palette)
        let date = configuration.viewModel.getPostDate(postID: configuration.repostID)
        switch configuration.postKind {
        case .regular:
            grayTextButton.setTitle(date, for: .normal)
        case .repost(let repostInfo):
            let grayText = repostInfo.entity.grayText(date)
            grayTextButton.setTitle(grayText, for: .normal)
        }

        addOrRemoveSubview(detailsButton, if: configuration.hasDetailsButton)

        paletteSubscription = configuration.palette.$palette
            .sink { [weak self] palette in
                self?.paletteDidUpdate(palette)
            }

        traitCollectionDidChange(nil)
    }

    private func paletteDidUpdate(_ palette: Palette) {
        updateAuthorName(palette)
        authorNameButton.tintColor = palette.$accent.uiColor
        grayTextButton.tintColor = palette.$grayText.uiColor
        setNeedsDisplay()
    }

    private var topInset: CGFloat {
        switch configuration.postKind {
        case .regular:
            traitCollection.horizontalSizeClass == .regular ? 13 : 7
        case .repost:
            traitCollection.horizontalSizeClass == .regular ? 10 : 6
        }
    }

    private var metrics: PostViewMetrics {
        PostViewMetrics(horizontalSizeClass: traitCollection.horizontalSizeClass)
    }

    private var authorNameX: CGFloat {
        metrics.horizontalInset
            + metrics.totalRepostOffset(postKind: configuration.postKind)
            + imageSize
            + 8
    }

    private func availableTitleSize(cellWidth: CGFloat) -> CGSize {
        let metrics = self.metrics
        let detailButtonWidthWithPadding = configuration.hasDetailsButton
            ? metrics.detailButtonSize.width + 8
            : 0
        return CGSize(
            width: cellWidth
                - authorNameX
                - detailButtonWidthWithPadding
                - metrics.horizontalInset,
            height: .greatestFiniteMagnitude,
        )
    }

    private var grayTextTopSpacing: CGFloat { 2 }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setNeedsDisplay()
        setNeedsLayout()
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard traitCollection.horizontalSizeClass == .regular,
              case .repost(let repostInfo) = configuration.postKind,
              let context = UIGraphicsGetCurrentContext() else {
            return
        }
        let metrics = self.metrics
        let horizontalInset = metrics.horizontalInset
        let singleRepostOffset = metrics.singleRepostOffset
        let lineThickness = metrics.repostVerticalLineThickness
        let topInset = self.topInset

        context.setStrokeColor(configuration.palette.$repostVerticalLine.cgColor)
        context.setLineWidth(lineThickness)

        for level in 0...repostInfo.level {
            context.beginPath()
            let offset: CGFloat =
                horizontalInset + lineThickness / 2 + singleRepostOffset * CGFloat(level)
            let y = level == repostInfo.level ? topInset : 0
            context.addLines(
                between: [
                    CGPoint(x: offset, y: y),
                    CGPoint(x: offset, y: bounds.height)
                ]
            )
            context.strokePath()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let metrics = self.metrics
        let horizontalInset = metrics.horizontalInset
        let profilePictureSize = self.imageSize
        profilePictureButton.frame = CGRect(
            x: horizontalInset
                + metrics.totalRepostOffset(postKind: configuration.postKind),
            y: topInset,
            width: profilePictureSize,
            height: profilePictureSize,
        )

        let availableTitleSize = availableTitleSize(cellWidth: bounds.width)
        authorNameButton.frame.size = authorNameButton.sizeThatFits(availableTitleSize)
        grayTextButton.frame.size = grayTextButton.sizeThatFits(availableTitleSize)

        let authorNameAndGrayTextStackHeight = authorNameButton.frame.size.height
            + grayTextTopSpacing
            + grayTextButton.frame.size.height

        // Center the stack relative to the profile picture if it's height is less than
        // the height of the profile picture, otherwise align their top borders.
        authorNameButton.frame.origin = CGPoint(
            x: authorNameX,
            y: topInset
                + max(0, (profilePictureSize - authorNameAndGrayTextStackHeight) / 2),
        )

        grayTextButton.frame.origin = CGPoint(
            x: authorNameX,
            y: authorNameButton.frame.maxY + grayTextTopSpacing
        )

        if configuration.hasDetailsButton {
            let detailButtonSize = metrics.detailButtonSize
            detailsButton.frame = CGRect(
                origin: CGPoint(
                    x: bounds.width - horizontalInset - detailButtonSize.width,
                    y: topInset,
                ),
                size: detailButtonSize
            )
        }
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let availableTitleSize = availableTitleSize(cellWidth: size.width)
        let height = topInset + max(
            imageSize,
            authorNameButton.sizeThatFits(availableTitleSize).height
                + grayTextTopSpacing
                + grayTextButton.sizeThatFits(availableTitleSize).height,
        )

        return CGSize(width: size.width, height: height)
    }

    @objc
    private func navigateToPostAuthor() {
        let author = configuration.author
        if let userID = author.id?.userID {
            configuration
                .pushToNavigationStack?(UserProfileNavigationItem(userID: userID))
        } else if let _ = author.id?.groupID {
            // TODO: Navigate to group
        } else {
            configuration
                .pushToNavigationStack?(UserProfileNavigationItem(userID: nil))
        }
    }
}
