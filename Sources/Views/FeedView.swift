import Prefire
import SwiftUI

struct FeedView: View {
    @ObservedObject var viewModel: FeedViewModel

    @EnvironmentObject private var errorObserver: ErrorObserver

    @EnvironmentObject private var palette: PaletteHolder
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var composePostShown = false

    private func refreshFeed() async {
        await errorObserver.runCatching {
            try await viewModel.update()
        }
    }

    var body: some View {
        FeedViewControllerAdaptor(viewModel: viewModel)
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

    var refresh: RefreshAction?

    private let topRefreshControl = UIRefreshControl()

    private static func createLayout() -> UICollectionViewCompositionalLayout {
        return UICollectionViewCompositionalLayout {
 _,
 layoutEnv in
            let itemLayoutSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .estimated(100),
            )
            let item = NSCollectionLayoutItem(layoutSize: itemLayoutSize)
            item.contentInsets = .zero
            let isWide = layoutEnv.traitCollection.horizontalSizeClass == .regular
            item.contentInsets = NSDirectionalEdgeInsets(
                top: 0,
                leading: isWide ? 24 : 0,
                bottom: 0,
                trailing: isWide ? 24 : 0,
            )
            let group = NSCollectionLayoutGroup.vertical(
                layoutSize: itemLayoutSize,
                subitems: [item],
            )
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(
                top: isWide ? 16 : 0,
                leading: 0,
                bottom: 0,
                trailing: 0,
            )
            section.interGroupSpacing = isWide ? 13 : 2
            return section
        }
    }

    init(viewModel: FeedViewModel) {
        self.viewModel = viewModel
        super.init(collectionViewLayout: Self.createLayout())
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
        collectionView.registerReuseIdentifier(.post)
        collectionView.refreshControl = topRefreshControl
        collectionView.contentInsetAdjustmentBehavior = .never
    }

    @objc private func pullToRefresh() {
        Task {
            await refresh?.callAsFunction()
            topRefreshControl.endRefreshing()
        }
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int,
    ) -> Int {
        return viewModel.posts.count
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath,
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: .post,
            for: indexPath
        )

        let postViewModel = viewModel.posts[indexPath.item]

        cell.contentConfiguration =
            UIHostingConfigurationPolyfill(parentViewController: self) {
                if traitCollection.horizontalSizeClass == .regular {
                    RegularPostView(viewModel: postViewModel)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .shadow(
                            color: Color(#colorLiteral(red: 0.8445754647, green: 0.8591627479, blue: 0.8676676154, alpha: 1)),
                            radius: 0,
                            x: 0,
                            y: 1,
                        )
                } else {
                    CompactPostView(viewModel: postViewModel)
                }
            }
            .margins(.all, 0)

        return cell
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

extension CellReuseIdentifier<UICollectionViewCell> {
    static let post = Self(rawValue: "post")
}

private struct FeedViewControllerAdaptor: UIViewControllerRepresentable {
    @ObservedObject var viewModel: FeedViewModel

    func makeUIViewController(context: Context) -> FeedViewController {
        return FeedViewController(viewModel: viewModel)
    }

    func updateUIViewController(
        _ uiViewController: FeedViewController,
        context: Context
    ) {
        uiViewController.refresh = context.environment.refresh
        // FIXME: reloadData is bad
        uiViewController.collectionView.reloadData()
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
