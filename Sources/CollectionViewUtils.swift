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

struct CollectionViewDecorationKind<View: UIView>: RawRepresentable {
    var rawValue: String
}

extension UICollectionViewLayout {
    func registerDecorationView<View: UICollectionReusableView>(
        ofKind kind: CollectionViewDecorationKind<View>
    ) {
        register(View.self, forDecorationViewOfKind: kind.rawValue)
    }
}

extension NSCollectionLayoutDecorationItem {
    static func background<View: UICollectionReusableView>(
        elementKind: CollectionViewDecorationKind<View>
    ) -> Self {
        background(elementKind: elementKind.rawValue)
    }
}

