import SwiftUI
import SwiftUIIntrospect

private struct ContentMarginPolyfillViewModifier: ViewModifier {
    let edges: Edge.Set
    let length: CGFloat
    @Environment(\.layoutDirection) private var layoutDirection

    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            return content.contentMargins(edges, length)
        }
        return content.introspect(.scrollView, on: .iOS(.v15, .v16)) { scrollView in
            if edges.contains(.top) {
                scrollView.contentInset.top = length
            }
            if edges.contains(.bottom) {
                scrollView.contentInset.bottom = length
            }
            if edges.contains(.leading) {
                switch layoutDirection {
                case .leftToRight:
                    scrollView.contentInset.left = length
                case .rightToLeft:
                    scrollView.contentInset.right = length
                @unknown default:
                    fatalError("unreachable, iOS >17 is handled above")
                }
            }
            if edges.contains(.trailing) {
                switch layoutDirection {
                case .leftToRight:
                    scrollView.contentInset.right = length
                case .rightToLeft:
                    scrollView.contentInset.left = length
                @unknown default:
                    fatalError("unreachable, iOS >17 is handled above")
                }
            }
        }
    }
}

extension View {
    func navigationBarBackground(_ color: Color) -> some View {
        if #available(iOS 16.0, *) {
            return toolbarBackground(color, for: .navigationBar)
        } else {
            return introspect(.navigationView(style: .stack), on: .iOS(.v15)) { nc in
                let uiColor = UIColor(color)
                nc.navigationBar.backgroundColor = uiColor
                let appearance = nc.navigationBar.standardAppearance
                appearance.backgroundColor = uiColor
                nc.navigationBar.compactAppearance = appearance
                nc.navigationBar.scrollEdgeAppearance = appearance
                nc.navigationBar.compactScrollEdgeAppearance = appearance
            }
        }
    }

    @ViewBuilder
    func navigationBarBackground(_ visibility: Visibility) -> some View {
        if #available(iOS 18.0, *) {
            toolbarBackgroundVisibility(visibility, for: .navigationBar)
        } else if #available(iOS 16, *) {
            toolbarBackground(visibility, for: .navigationBar)
        } else {
            introspect(.navigationView(style: .stack), on: .iOS(.v15)) { nc in
                let appearance = nc.navigationBar.standardAppearance
                switch visibility {
                case .automatic:
                    appearance.configureWithDefaultBackground()
                case .hidden:
                    appearance.configureWithTransparentBackground()
                case .visible:
                    appearance.configureWithOpaqueBackground()
                }
                nc.navigationBar.compactAppearance = appearance
                nc.navigationBar.scrollEdgeAppearance = appearance
                nc.navigationBar.compactScrollEdgeAppearance = appearance
            }
        }
    }

    func navigationBarColorScheme(_ colorScheme: ColorScheme?) -> some View {
        if #available(iOS 16.0, *) {
            return toolbarColorScheme(colorScheme, for: .navigationBar)
        } else {
            return introspect(.navigationView(style: .stack), on: .iOS(.v15)) { nc in
                let textColor: UIColor =
                    switch colorScheme {
                    case .dark:
                        .white
                    case .light:
                        .black
                    case nil:
                        .label
                    @unknown default:
                        .label
                    }
                nc.navigationBar.titleTextAttributes?[.foregroundColor] = textColor
            }
        }
    }

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
                        var listConfig = UICollectionLayoutListConfiguration(
                            appearance: .insetGrouped
                        )

                        // NOTE: Because we're replacing the layout, the value of
                        // scrollContentBackground is not respected,
                        // so we hide it unconditionally because there's nowhere to
                        listConfig.backgroundColor = .clear

                        let section = NSCollectionLayoutSection.list(
                            using: listConfig,
                            layoutEnvironment: layoutEnvironment
                        )

                        section.contentInsets.bottom = 0
                        if i > 0 {
                            section.contentInsets.top = spacing
                        }

                        return section
                    },
                    configuration: layout.configuration,
                )
        }
    }

    func scrollDisabledPolyfill(_ disabled: Bool) -> some View {
        if #available(iOS 16.0, *) {
            return scrollDisabled(disabled)
        }
        return introspect(.scrollView, on: .iOS(.v15, .v16)) { scrollView in
            scrollView.isScrollEnabled = false
        }
    }

    func scrollContentBackgroundPolyfill(_ visibility: Visibility) -> some View {
        if #available(iOS 16.0, *) {
            return scrollContentBackground(visibility)
        }
        return introspect(.list, on: .iOS(.v15)) { tableView in
            switch visibility {
            case .hidden:
                tableView.backgroundColor = nil
            default:
                break
            }
        }
    }

    func contentMarginsPolyfill(_ edges: Edge.Set, _ length: CGFloat) -> some View {
        modifier(ContentMarginPolyfillViewModifier(edges: edges, length: length))
    }

    func draggableAsURL(_ url: URL) -> some View {
        if #available(iOS 16.0, *) {
            return draggable(url)
        } else {
            return self
        }
    }
}

extension View {
    // periphery:ignore
    func debugBorder(_ color: Color = .red) -> some View {
        border(color)
    }
}
