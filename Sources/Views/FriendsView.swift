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

private final class FriendsViewController
    : UICollectionViewController,
      UICollectionViewDataSourcePrefetching
{
    private let db: SmithereenDatabase
    private var observation: AnyDatabaseCancellable?

    var pushToNavigationStack: ((any Hashable) -> Void)?

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

    private struct Identified<T: Identifiable & Sendable>: Hashable, Sendable {
        var value: T
        func hash(into hasher: inout Hasher) {
            hasher.combine(value.id)
        }

        static func == (lhs: Self, rhs: Self) -> Bool {
            return lhs.value.id == rhs.value.id
        }
    }

    private let friendCellRegistration = UICollectionView
        .CellRegistration<UICollectionViewListCell, Identified<User>> { cell, _, user in
            var attrContainer = AttributeContainer()
            attrContainer.personNameComponent = .familyName

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
            contentConfiguration.imageProperties.maximumSize = CGSize(width: 42, height: 42)
            contentConfiguration.image = UIImage(resource: .boromirProfilePicture)
            cell.contentConfiguration = contentConfiguration
        }

    private var sectionHeaderRegistration: UICollectionView .SupplementaryRegistration<UICollectionViewListCell>!

    private var dataSource: ActorDiffableDataSource<Section, Identified<User>>!

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.prefetchDataSource = self
        let dataSource = ActorDiffableDataSource<Section, Identified<User>>(
            collectionView: collectionView,
        ) { [unowned self] collectionView, indexPath, user in
            collectionView.dequeueConfiguredReusableCell(
                using: self.friendCellRegistration,
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
                .order {
                    [$0.lastName.ascNullsLast, $0.firstName]
                }
                .fetchAll(db)
        }
        .start(
            in: db.reader,
            onError: { _ in },
            onChange: { users in
                var snapshot = NSDiffableDataSourceSnapshot<Section, Identified<User>>()
                var lastIndexTitle: String?
                for user in users {
                    let indexTitle: String
                    if let firstChar = user.lastName?.first ?? user.firstName.first,
                       firstChar.isLetter {
                        indexTitle = firstChar.uppercased()
                    } else {
                        indexTitle = "#"
                    }
                    if lastIndexTitle != indexTitle {
                        lastIndexTitle = indexTitle
                        snapshot.appendSections([.alphabet(indexTitle)])
                    }
                    snapshot.appendItems([Identified(value: user)])
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
        // TODO
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cancelPrefetchingForItemsAt indexPaths: [IndexPath],
    ) {
        // TODO
    }

    // MARK: - Collection view delegate

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

    func makeUIViewController(context: Context) -> FriendsViewController {
        return FriendsViewController(db: db)
    }

    func updateUIViewController(_ vc: FriendsViewController, context: Context) {
        vc.pushToNavigationStack = context.environment.pushToNavigationStack
    }
}

#Preview("Friends") {
    FriendsView(db: try! .createInMemory())
}
