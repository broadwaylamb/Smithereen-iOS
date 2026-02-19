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

private final class FriendsViewController
    : UICollectionViewController,
      UICollectionViewDataSourcePrefetching
{
    private static let cellReuseID = "actorCell"
    private var observation: AnyDatabaseCancellable?
    private var users: [User] = []

    var pushToNavigationStack: ((any Hashable) -> Void)?

    init(db: SmithereenDatabase) {
        let listConfiguration = UICollectionLayoutListConfiguration(appearance: .plain)
        super.init(
            collectionViewLayout: UICollectionViewCompositionalLayout.list(
                using: listConfiguration
            )
        )
        observation = ValueObservation.tracking { db in
            try User
                .filter { $0.isFriend == true } // TODO: Use the friendship table/
                .limit(10000) // Smithereen limit for the number of friends
                .order {
                    [$0.lastName, $0.firstName]
                }
                .fetchAll(db)
        }
        .start(in: db.reader, onError: { _ in  }, onChange: { [unowned self] users in
            self.users = users
            collectionView.reloadData() // FIXME: NO NO NO
        })
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.register(
            UICollectionViewListCell.self,
            forCellWithReuseIdentifier: Self.cellReuseID,
        )
        collectionView.prefetchDataSource = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    // MARK: - Collection view data source

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int,
    ) -> Int {
        return users.count
    }

    override func indexTitles(for collectionView: UICollectionView) -> [String]? {
        return nil
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        indexPathForIndexTitle title: String,
        at index: Int,
    ) -> IndexPath {
        fatalError()
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath,
    ) -> UICollectionViewCell {
        let cell = collectionView
            .dequeueReusableCell(withReuseIdentifier: Self.cellReuseID, for: indexPath)
            as! UICollectionViewListCell
        let user = users[indexPath.row]

        var attrContainer = AttributeContainer()
        attrContainer.personNameComponent = .familyName

        var newContainer = AttributeContainer()
        newContainer.uiKit.font = .preferredFont(forTextStyle: .body)
        newContainer.inlinePresentationIntent.insert(.stronglyEmphasized)

        let attributedName = user
            .nameComponents
            .formatted(.name(style: .medium).attributed)
            .replacingAttributes(attrContainer, with: newContainer)

        var contentConfiguration = cell.defaultContentConfiguration()
        contentConfiguration.attributedText = NSAttributedString(attributedName)
        contentConfiguration.imageProperties.maximumSize = CGSize(width: 42, height: 42)
        contentConfiguration.image = UIImage(resource: .boromirProfilePicture)
        cell.contentConfiguration = contentConfiguration
        return cell
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
        pushToNavigationStack?(UserProfileNavigationItem(userID: users[indexPath.row].id))
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
