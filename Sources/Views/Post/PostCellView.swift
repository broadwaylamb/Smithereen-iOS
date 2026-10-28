import UIKit

struct PostCellConfiguration: UIContentConfiguration {
    var viewModel: PostViewModel

    func makeContentView() -> any UIView & UIContentView {
        return PostCellView(configuration: self)
    }

    func updated(for state: any UIConfigurationState) -> PostCellConfiguration {
        self
    }
}

private struct PostHeaderInfo {
    var kind: PostKind
    var author: PostAuthor
    var date: String
    var originalURL: URL
    var canDelete: Bool
    var canEdit: Bool
    var canPin: Bool
    var isOwnPost: Bool
}

private final class PostHeaderUIView: UIView {
    var info: PostHeaderInfo

    init(info: PostHeaderInfo) {
        self.info = info
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var imageBaseSize: CGFloat {
        switch (info.kind, traitCollection.horizontalSizeClass) {
        case (.regular, .regular):
            55
        case (.regular, _):
            40
        case (_, .regular):
            50
        case (_, _):
            32
        }
    }
}

private final class PostCellView: UIView, UIContentView {
    var configuration: UIContentConfiguration {
        didSet {
            configure()
        }
    }

    let mainHeaderView: PostHeaderUIView

    init(configuration: PostCellConfiguration) {
        self.configuration = configuration
        let vm = configuration.viewModel
        self.mainHeaderView = PostHeaderUIView(
            info: PostHeaderInfo(
                kind: .regular,
                author: vm.getAuthor(),
                date: vm.getPostDate(),
                originalURL: vm.originalPostURL,
                canDelete: vm.post.canDelete,
                canEdit: vm.post.canEdit,
                canPin: vm.post.canPin ?? false,
                isOwnPost: vm.isOwnPost,
            )
        )
        super.init(frame: .zero)
        backgroundColor = .red
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func supports(_ configuration: any UIContentConfiguration) -> Bool {
        configuration is PostCellConfiguration
    }

    func configure() {
        guard let viewModel = (configuration as? PostCellConfiguration)?.viewModel else {
            return
        }
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        mainHeaderView.sizeThatFits(size)
    }
}
