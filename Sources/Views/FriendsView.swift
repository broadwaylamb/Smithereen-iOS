import GRDB
import SmithereenAPI
import SwiftUI
import UIKit

struct FriendsView: View {
    var db: SmithereenDatabase

    var body: some View {
        FriendsViewAdapter(db: db)
    }
}

private protocol SectionWithIndexTitle: Hashable, Sendable {
    var indexTitle: String { get }
}

private final class ActorDiffableDataSource<SectionIdentifierType, ItemIdentifierType>
    : UICollectionViewDiffableDataSource<SectionIdentifierType, ItemIdentifierType>
    where SectionIdentifierType: SectionWithIndexTitle,
          ItemIdentifierType: Hashable,
          ItemIdentifierType: Sendable
{
    override func indexTitles(for collectionView: UICollectionView) -> [String]? {
        self.snapshot().sectionIdentifiers.map { section in
            section.indexTitle
        }
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        indexPathForIndexTitle title: String,
        at index: Int,
    ) -> IndexPath {
        return IndexPath(item: 0, section: index)
    }
}

private let profilePictureSize = CGSize(width: 42, height: 42)

private final class FriendsViewController
    : UICollectionViewController,
      UICollectionViewDataSourcePrefetching
{
    private let db: SmithereenDatabase
    private var observation: AnyDatabaseCancellable?

    var pushToNavigationStack: ((any Hashable) -> Void)?
    var roundProfilePictures: Bool = false

    init(db: SmithereenDatabase) {
        self.db = db
        var listConfiguration = UICollectionLayoutListConfiguration(appearance: .plain)
        listConfiguration.headerMode = .supplementary
        super.init(
            collectionViewLayout: UICollectionViewCompositionalLayout.list(
                using: listConfiguration
            )
        )
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private enum Section: SectionWithIndexTitle {
        case important
        case alphabet(String)

        var indexTitle: String {
            switch self {
            case .important:
                return "☆"
            case .alphabet(let string):
                return string
            }
        }
    }

    private struct ActorListItem<T: Identifiable & Sendable>: Hashable, Sendable {
        var imageViewModel: AsyncImageViewModel
        var value: T
        func hash(into hasher: inout Hasher) {
            hasher.combine(value.id)
        }

        static func == (lhs: Self, rhs: Self) -> Bool {
            return lhs.value.id == rhs.value.id
        }
    }

    private var sectionHeaderRegistration: UICollectionView.SupplementaryRegistration<UICollectionViewListCell>!

    private var dataSource: ActorDiffableDataSource<Section, ActorListItem<User>>!

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.prefetchDataSource = self

        let friendCellRegistration = UICollectionView
            .CellRegistration<UICollectionViewListCell, ActorListItem<User>> { [unowned self] cell, _, user in
                var attrContainer = AttributeContainer()
                attrContainer.personNameComponent =
                    user.value.lastName != nil ? .familyName : .givenName

                var newContainer = AttributeContainer()
                newContainer.uiKit.font = .preferredFont(forTextStyle: .body)
                newContainer.inlinePresentationIntent.insert(.stronglyEmphasized)

                let attributedName = user
                    .value
                    .nameComponents
                    .formatted(.name(style: .medium).attributed)
                    .replacingAttributes(attrContainer, with: newContainer)

                var contentConfiguration = cell.defaultContentConfiguration()
                contentConfiguration.attributedText = NSAttributedString(attributedName)

                contentConfiguration.imageProperties.cornerRadius = roundProfilePictures
                    ? profilePictureSize.width / 2
                    : 2.5
                contentConfiguration.imageProperties.maximumSize = profilePictureSize

                // TODO: Set a placeholder image if there isn't any avatar
                contentConfiguration.image = user.imageViewModel.currentImage
                cell.contentConfiguration = contentConfiguration
            }

        let dataSource = ActorDiffableDataSource<Section, ActorListItem<User>>(
            collectionView: collectionView,
        ) { collectionView, indexPath, user in
            collectionView.dequeueConfiguredReusableCell(
                using: friendCellRegistration,
                for: indexPath,
                item: user,
            )
        }
        sectionHeaderRegistration = UICollectionView
            .SupplementaryRegistration<UICollectionViewListCell>(
                elementKind: UICollectionView.elementKindSectionHeader
            ) { headerView, elementKind, indexPath in
                var contentConfiguration = headerView.defaultContentConfiguration()
                contentConfiguration.text =
                    switch dataSource.sectionIdentifier(for: indexPath.section) {
                    case .important:
                        String(localized: "Important")
                    case .alphabet(let s):
                        s
                    case nil:
                        nil
                    }
                headerView.contentConfiguration = contentConfiguration
            }
        dataSource.supplementaryViewProvider = { [unowned self] collectionView, _, indexPath in
            collectionView.dequeueConfiguredReusableSupplementary(
                using: self.sectionHeaderRegistration,
                for: indexPath,
            )
        }
        self.dataSource = dataSource
        observation = ValueObservation.tracking { db in
            try User
                .filter { $0.isFriend == true } // TODO: Use the friendship table/
                .limit(10000) // Smithereen limit for the number of friends
                .fetchAll(db)
                .sorted(using: UserNameComparator(order: .forward))
        }
        .start(
            in: db.reader,
            onError: { _ in },
            onChange: { users in
                var snapshot = NSDiffableDataSourceSnapshot<Section, ActorListItem<User>>()
                var lastIndexTitle: String?
                for user in users {
                    let indexTitle: String
                    if let firstChar = user.nameForSorting.first, firstChar.isLetter {
                        indexTitle = firstChar.uppercased()
                    } else {
                        indexTitle = "#"
                    }
                    if lastIndexTitle != indexTitle {
                        lastIndexTitle = indexTitle
                        let identifier = Section.alphabet(indexTitle)
                        // This check is necessary, because otherwise `appendSections`
                        // may throw an exception
                        if snapshot.indexOfSection(identifier) == nil {
                            snapshot.appendSections([identifier])
                        } else {
                            assertionFailure("""
                                Section with identifier \(indexTitle) already exists \
                                in the snapshot
                                """)
                        }
                    }
                    let profilePictureViewModel = AsyncImageViewModel(
                        sizes: user.squareProfilePictureSizes,
                        blurHash: nil,
                    )
                    let item = ActorListItem(
                        imageViewModel: profilePictureViewModel,
                        value: user,
                    )
                    snapshot.appendItems([item])
                }
                dataSource.apply(snapshot)
            },
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    // MARK: - Collection view prefetching

    func collectionView(
        _ collectionView: UICollectionView,
        prefetchItemsAt indexPaths: [IndexPath],
    ) {
        for indexPath in indexPaths {
            guard let item = dataSource.itemIdentifier(for: indexPath) else { continue }
            item.imageViewModel.loadImage(
                fitting: profilePictureSize,
                displayScale: traitCollection.displayScale,
            )
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cancelPrefetchingForItemsAt indexPaths: [IndexPath],
    ) {
        for indexPath in indexPaths {
            guard let item = dataSource.itemIdentifier(for: indexPath) else { continue }
            item.imageViewModel.cancelLoading()
        }
    }

    // MARK: - Collection view delegate

    override func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath,
    ) {
        dataSource.itemIdentifier(for: indexPath)?.imageViewModel.loadImage(
            fitting: profilePictureSize,
            displayScale: traitCollection.displayScale,
        ) { [weak self] phase in
            if let cell = self?
                .collectionView?
                .cellForItem(at: indexPath) as? UICollectionViewListCell,
               var configuration = cell.contentConfiguration as? UIListContentConfiguration
            {
                configuration.image = phase.image
                cell.contentConfiguration = configuration
            }
        }
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath,
    ) {
        if let user = dataSource.itemIdentifier(for: indexPath)?.value {
            pushToNavigationStack?(UserProfileNavigationItem(userID: user.id))
        }
    }
}

private struct FriendsViewAdapter: UIViewControllerRepresentable {
    let db: SmithereenDatabase
    @AppStorage(.roundProfilePictures) private var roundProfilePictures

    func makeUIViewController(context: Context) -> FriendsViewController {
        return FriendsViewController(db: db)
    }

    func updateUIViewController(_ vc: FriendsViewController, context: Context) {
        vc.pushToNavigationStack = context.environment.pushToNavigationStack
        vc.roundProfilePictures = roundProfilePictures
    }
}

#Preview("Friends") {
    FriendsView(db: try! .createInMemory())
}
