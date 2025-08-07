import SwiftUI

/// A polyfill for `Group.init(subviews:transform:)`
struct ExtractSubviews<Base: View, Result: View>: View {
    private struct Root: _VariadicView_UnaryViewRoot {
        let transform: (_VariadicView_Children) -> Result

        func body(children: _VariadicView_Children) -> Result {
            transform(children)
        }
    }

    private let base: Base
    private let root: Root

    init(
        from base: Base,
        @ViewBuilder transform: @escaping (_VariadicView_Children) -> Result,
    ) {
        self.base = base
        self.root = Root(transform: transform)
    }

    var body: some View {
        _VariadicView.Tree(root, content: { base })
    }
}
