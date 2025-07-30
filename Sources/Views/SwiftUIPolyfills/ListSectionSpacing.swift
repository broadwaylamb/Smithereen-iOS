import SwiftUI
import UIKit

extension View {
    func listSectionSpacingPolyfill(_ spacing: CGFloat) -> some View {
        if #available(iOS 17.0, *) {
            return listSectionSpacing(spacing)
        }
        return introspect(.list, on: .iOS(.v15)) { tableView in
            tableView.sectionHeaderHeight = spacing / 2
            tableView.sectionFooterHeight = spacing / 2
        }
        .introspect(.list, on: .iOS(.v16)) { collectionView in
            guard
                let layout = collectionView.collectionViewLayout
                    as? UICollectionViewCompositionalLayout
            else { return }
            collectionView.collectionViewLayout =
                UICollectionViewCompositionalLayout(
                    sectionProvider: { i, layoutEnvironment in
                        let section = layout.sectionProvider(i, layoutEnvironment)

                        if let section {
                            section.contentInsets.bottom = 0
                            if i > 0 {
                                section.contentInsets.top = spacing
                            }
                        }

                        return section
                    },
                    configuration: layout.configuration,
                )
        }
    }
}

extension UICollectionViewCompositionalLayout {
    private typealias SectionProvider =
        @convention(block)
            (Int, any NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection?

    fileprivate var sectionProvider: UICollectionViewCompositionalLayoutSectionProvider {
        // Using a private API here, but this code is only ever invoked on iOS 16 which
        // is quite old. Nothing will break here.
        return unsafeBitCast(
            value(forKey: "_layoutSectionProvider") as AnyObject?,
            to: SectionProvider.self,
        )
    }
}
