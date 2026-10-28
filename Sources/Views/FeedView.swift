import SwiftUI
import Combine

struct FeedView: View {
    @ObservedObject var viewModel: FeedViewModel

    @EnvironmentObject private var errorObserver: ErrorObserver

    @EnvironmentObject private var palette: PaletteHolder

    @State private var composePostShown = false

    private func refreshFeed() async {
        await errorObserver.runCatching {
            try await viewModel.update()
        }
    }

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
            .task {
                await refreshFeed()
            }
            .refreshable {
                await refreshFeed()
            }
            .background(palette.feedBackground)
            .colorScheme(.light)
    }
}

private final class FeedViewController: UICollectionViewController {
    private let viewModel: FeedViewModel
    private let palette: PaletteHolder

    var refresh: RefreshAction?

    var pushToNavigationStack: ((any Hashable) -> ())?

    private let topRefreshControl = UIRefreshControl()

    private var cancellables = Set<AnyCancellable>()

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

            let isWide = layoutEnv.traitCollection.horizontalSizeClass == .regular
            let bgInsets = NSDirectionalEdgeInsets(
                top: isWide && sectionIndex == 0 ? 16 : 0,
                leading: isWide ? 24 : 0,
                bottom: isWide ? 13 : 2, // Inter-section spacing
                trailing: isWide ? 24 : 0,
            )
            sectionBackgroundDecoration.contentInsets = bgInsets
            section.decorationItems = [sectionBackgroundDecoration]

            section.contentInsets = NSDirectionalEdgeInsets(
                top: bgInsets.top,
                leading: bgInsets.leading,
                bottom: bgInsets.bottom + (isWide ? 0 : 11),
                trailing: bgInsets.trailing,
            )
            return section
        }
        layout.registerDecorationView(ofKind: .feedSectionBackgroundView)
        return layout
    }

    init(viewModel: FeedViewModel, palette: PaletteHolder) {
        self.viewModel = viewModel
        self.palette = palette
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

    @objc private func pullToRefresh() {
        Task {
            await refresh?.callAsFunction()
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

    func makeUIViewController(context: Context) -> FeedViewController {
        return FeedViewController(viewModel: viewModel, palette: palette)
    }

    func updateUIViewController(
        _ uiViewController: FeedViewController,
        context: Context
    ) {
        uiViewController.refresh = context.environment.refresh
        uiViewController.pushToNavigationStack = context.environment.pushToNavigationStack
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
