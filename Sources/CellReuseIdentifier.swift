import UIKit

struct CellReuseIdentifier<T>: RawRepresentable {
    var rawValue: String
}

extension UICollectionView {
    func registerReuseIdentifier<Cell: UICollectionViewCell>(
        _ reuseIdentifier: CellReuseIdentifier<Cell>
    ) {
        register(Cell.self, forCellWithReuseIdentifier: reuseIdentifier.rawValue)
    }

    func dequeueReusableCell<Cell: UICollectionViewCell>(
        withReuseIdentifier reuseIdentifier: CellReuseIdentifier<Cell>,
        for indexPath: IndexPath,
    ) -> Cell {
        dequeueReusableCell(
            withReuseIdentifier: reuseIdentifier.rawValue,
            for: indexPath
        ) as! Cell
    }
}

