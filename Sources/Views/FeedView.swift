import SwiftUI
import Combine

struct FeedView: View {
    @ObservedObject var viewModel: FeedViewModel

    @EnvironmentObject private var errorObserver: ErrorObserver

    @EnvironmentObject private var palette: PaletteHolder

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.displayScale) private var displayScale

    @State private var composePostShown = false

    var body: some View {
        FeedViewControllerAdaptor(viewModel: viewModel)
            .ignoresSafeArea()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        composePostShown = true
                    } label: {
                        Image(.composePost)
                    }
                    .tint(Color.white)
                }
                .disableLiquidShit()
            }
            .sheet(isPresented: $composePostShown) {
                ComposePostView(
                    "New Post",
                    placeholder: "What's new?",
                    viewModel: viewModel.createComposePostViewModel(
                        errorObserver: errorObserver,
                        isShown: $composePostShown,
                    ),
                )
            }
            .background(palette.feedBackground)
            .colorScheme(.light)
    }
}

private final class FeedViewController: UICollectionViewController {
    private let viewModel: FeedViewModel
    private let palette: PaletteHolder
    var errorObserver: ErrorObserver

    var pushToNavigationStack: ((any Hashable) -> ())?

    private let topRefreshControl = UIRefreshControl()

    private var cancellables = Set<AnyCancellable>()

    private nonisolated static func backgroundInsets(
        traitCollection: UITraitCollection,
        sectionIndex: Int,
    ) -> NSDirectionalEdgeInsets {
        let isWide = traitCollection.horizontalSizeClass == .regular
        return NSDirectionalEdgeInsets(
            top: isWide && sectionIndex == 0 ? 16 : 0,
            leading: isWide ? 24 : 0,
            bottom: isWide ? 13 : 2, // Inter-section spacing
            trailing: isWide ? 24 : 0,
        )
    }

    private nonisolated static func sectionContentInsets(
        traitCollection: UITraitCollection,
        sectionIndex: Int,
    ) -> NSDirectionalEdgeInsets {
        var insets = backgroundInsets(
            traitCollection: traitCollection,
            sectionIndex: sectionIndex
        )
        if traitCollection.horizontalSizeClass != .regular {
            insets.bottom += 11
        }
        return insets
    }

    private static func createLayout() -> UICollectionViewCompositionalLayout {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, layoutEnv in
            let itemLayoutSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .estimated(100),
            )
            let item = NSCollectionLayoutItem(layoutSize: itemLayoutSize)
            let group = NSCollectionLayoutGroup.vertical(
                layoutSize: itemLayoutSize,
                subitems: [item],
            )
            let section = NSCollectionLayoutSection(group: group)

            let sectionBackgroundDecoration = NSCollectionLayoutDecorationItem
                .background(elementKind: .feedSectionBackgroundView)

            sectionBackgroundDecoration.contentInsets = backgroundInsets(
                traitCollection: layoutEnv.traitCollection,
                sectionIndex: sectionIndex
            )
            section.decorationItems = [sectionBackgroundDecoration]

            section.contentInsets = sectionContentInsets(
                traitCollection: layoutEnv.traitCollection,
                sectionIndex: sectionIndex,
            )
            return section
        }
        layout.registerDecorationView(ofKind: .feedSectionBackgroundView)
        return layout
    }

    init(viewModel: FeedViewModel, palette: PaletteHolder, errorObserver: ErrorObserver) {
        self.viewModel = viewModel
        self.palette = palette
        self.errorObserver = errorObserver
        let layout = Self.createLayout()
        super.init(collectionViewLayout: layout)
        traitCollectionDidChange(nil)
        topRefreshControl
            .addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.prefetchDataSource = self
        collectionView.backgroundColor = nil
        collectionView.registerReuseIdentifier(.postHeader)
        collectionView.registerReuseIdentifier(.postFooter)
        collectionView.refreshControl = topRefreshControl

        viewModel.$posts.sink { [weak self] _ in
            self?.collectionView.reloadData() // FIXME: reloadData is bad!
        }.store(in: &cancellables)
    }

    private nonisolated static func refresh(
        viewModel: FeedViewModel,
        errorObserver: ErrorObserver,
        traitCollection: UITraitCollection,
        columnWidth: CGFloat
    ) async {
        await errorObserver.runCatching {
            let contentInsets = Self.sectionContentInsets(
                traitCollection: traitCollection,
                sectionIndex: 0,
            )
            let metrics = PostViewMetrics(
                horizontalSizeClass: traitCollection.horizontalSizeClass,
            )
            try await viewModel.update(
                textRenderingParameters: TextRenderingParameters(
                    contentSizeCategory: traitCollection.preferredContentSizeCategory,
                    displayScale: traitCollection.displayScale,
                    width: { repostLevel in
                        metrics.textWidth(
                            baseWidth: columnWidth
                                - contentInsets.leading
                                - contentInsets.trailing,
                            repostLevel: repostLevel
                        )
                    },
                )
            )
        }
    }

    @objc private func pullToRefresh() {
        Task(priority: .userInitiated) {
            await Self.refresh(
                viewModel: viewModel,
                errorObserver: errorObserver,
                traitCollection: traitCollection,
                columnWidth: collectionView.bounds.width,
            )
            topRefreshControl.endRefreshing()
        }
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return viewModel.posts.count
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int,
    ) -> Int {
        viewModel.posts[section].displayItems.count
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath,
    ) -> UICollectionViewCell {
        let postViewModel = viewModel.posts[indexPath.section]
        switch postViewModel.displayItems[indexPath.item] {
        case .header(let postKind):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: .postHeader,
                for: indexPath
            )
            cell.contentConfiguration = PostHeaderContentConfiguration(
                viewModel: postViewModel,
                postKind: postKind,
                palette: palette,
                pushToNavigationStack: pushToNavigationStack,
            )
            return cell
        case .footer:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: .postHeader,
                for: indexPath
            )
            cell.contentConfiguration =
                UIHostingConfigurationPolyfill(parentViewController: self) {
                    PostFooterView(viewModel: postViewModel)
                }
                .margins(.all, 0)
            return cell
        }
    }
}

extension FeedViewController: UICollectionViewDataSourcePrefetching {
    func collectionView(
        _ collectionView: UICollectionView,
        prefetchItemsAt indexPaths: [IndexPath]
    ) {
        // TODO
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cancelPrefetchingForItemsAt indexPaths: [IndexPath]
    ) {
        // TODO
    }
}

private extension CellReuseIdentifier<UICollectionViewCell> {
    static let postHeader = Self(rawValue: "postHeader")
    static let postFooter = Self(rawValue: "postHeader")
}

private final class FeedSectionBackgroundView: UICollectionReusableView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        layer.shadowColor = #colorLiteral(red: 0.8445754647, green: 0.8591627479, blue: 0.8676676154, alpha: 1)
        layer.shadowOffset = CGSize(width: 0, height: 1)
        layer.shadowRadius = 0
        traitCollectionDidChange(nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(
        _ previousTraitCollection: UITraitCollection?
    ) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.horizontalSizeClass == .regular {
            layer.cornerRadius = 4
            layer.shadowOpacity = 1.0
        } else {
            layer.cornerRadius = 0
            layer.shadowOpacity = 0
        }
    }
}

private extension CollectionViewDecorationKind<FeedSectionBackgroundView> {
    static let feedSectionBackgroundView = Self(rawValue: "feedSectionBackgroundView")
}

private struct FeedViewControllerAdaptor: UIViewControllerRepresentable {
    @ObservedObject var viewModel: FeedViewModel
    @EnvironmentObject var palette: PaletteHolder
    @EnvironmentObject var errorObserver: ErrorObserver

    func makeUIViewController(context: Context) -> FeedViewController {
        FeedViewController(
            viewModel: viewModel,
            palette: palette,
            errorObserver: errorObserver,
        )
    }

    func updateUIViewController(
        _ uiViewController: FeedViewController,
        context: Context
    ) {
        uiViewController.pushToNavigationStack = context.environment.pushToNavigationStack
        uiViewController.errorObserver = errorObserver
    }
}


#Preview {
    let api = MockApi()
    let vm = FeedViewModel(api: api, db: try! .createInMemory())
    FeedView(viewModel: vm)
        .environmentObject(PaletteHolder())
        .environmentObject(ErrorObserver())
        .prefireIgnored()
}
