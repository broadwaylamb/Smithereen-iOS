import UIKit

struct ReuseIdentifier<Cell> {
    var id: String
    init(_ id: String) {
        self.id = id
    }

    init() {
        id = "\(Cell.self)"
    }
}

extension UICollectionView {
    func register<Cell: UICollectionViewCell>(_ reuseIdentifier: ReuseIdentifier<Cell>) {
        register(Cell.self, forCellWithReuseIdentifier: reuseIdentifier.id)
    }

    func dequeueReusableCell<Cell: UICollectionViewCell>(
        withReuseIdentifier identifier: ReuseIdentifier<Cell>,
        for indexPath: IndexPath,
    ) -> Cell {
        return dequeueReusableCell(withReuseIdentifier: identifier.id, for: indexPath)
            as! Cell
    }
}
