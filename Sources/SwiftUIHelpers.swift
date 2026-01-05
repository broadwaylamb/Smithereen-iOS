import SwiftUI
import SwiftUIIntrospect

extension View {
    func navigationBarBackground(_ color: Color) -> some View {
        if #available(iOS 16.0, *) {
            return toolbarBackground(color, for: .navigationBar)
        } else {
            return introspect(.navigationView(style: .stack), on: .iOS(.v15)) { nc in
                // Set the colors on the next run loop cycle,
                // otherwise it will be initially black.
                DispatchQueue.main.async {
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
    }

    @ViewBuilder
    func navigationBarBackground(_ visibility: Visibility) -> some View {
        if #available(iOS 18.0, *) {
            toolbarBackgroundVisibility(visibility, for: .navigationBar)
        } else if #available(iOS 16, *) {
            toolbarBackground(visibility, for: .navigationBar)
        } else {
            // Doing nothing on iOS 15 is somehow better than doing something.
            self
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
#if DEBUG
        border(color)
#else
        self
#endif
    }
}

extension View {
    func listRowSeparatorLeadingInset(_ inset: CGFloat?) -> some View {
        if #available(iOS 16.0, *) {
            return alignmentGuide(.listRowSeparatorLeading) { d in
                inset ?? d[.listRowSeparatorLeading]
            }
        } else {
            return introspect(.listCell, on: .iOS(.v15)) { cell in
                if let inset {
                    cell.separatorInset.left = inset
                }
            }
        }
    }
}

struct ContentTransitionPolyfill {
    fileprivate var transition: () -> Any?

    static func numericText(value: Double) -> ContentTransitionPolyfill {
        ContentTransitionPolyfill {
            return if #available(iOS 17.0, *) {
                ContentTransition.numericText(value: value)
            } else {
                nil
            }
        }
    }
}

extension View {
    @ViewBuilder
    func contentTransitionIfAvailable(
        _ transition: ContentTransitionPolyfill,
    ) -> some View {
        if #available(iOS 16.0, *), let transition = transition.transition() {
            contentTransition(transition as! ContentTransition)
        } else {
            self
        }
    }
}

private struct Wrapper<T>: Identifiable {
    var wrapped: T

    struct ID: Hashable {}

    var id: ID { ID() }
}

extension View {
    func sheet<Item, Content: View>(
        item: Binding<Item?>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> Content,
    ) -> some View {
        let wrappedBinding = Binding {
            item.wrappedValue.map(Wrapper.init)
        } set: { newValue in
            item.wrappedValue = newValue?.wrapped
        }

        return sheet(item: wrappedBinding, onDismiss: onDismiss) { wrapper in
            content(wrapper.wrapped)
        }
    }
}
