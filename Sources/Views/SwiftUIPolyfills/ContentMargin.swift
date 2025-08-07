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
    func contentMarginsPolyfill(_ edges: Edge.Set, _ length: CGFloat) -> some View {
        modifier(ContentMarginPolyfillViewModifier(edges: edges, length: length))
    }
}

