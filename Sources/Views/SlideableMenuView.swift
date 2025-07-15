import SwiftUI

private let collapsibleMenuWidth: CGFloat = 276
private let alwaysShownMenuWidth: CGFloat = 256
private let dragThreshold: CGFloat = 138

struct SlideableMenuView<Menu: View, Content: View>: View {

    @Binding var isMenuShown: Bool

    @ViewBuilder
    var menu: () -> Menu

    @ViewBuilder
    var content: (Bool) -> Content

    @Environment(\.layoutDirection) private var layoutDirection

    @GestureState private var delta: CGFloat = 0

    private var start: CGFloat {
        isMenuShown ? collapsibleMenuWidth : 0
    }

    private func contentOffset(alwaysShowMenu: Bool) -> CGFloat {
        if alwaysShowMenu {
            return alwaysShownMenuWidth
        }
        return start + delta
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .updating($delta) { value, dragging, _ in
                var translationWidth = value.translation.width
                if layoutDirection == .rightToLeft {
                    translationWidth.negate()
                }
                let start = self.start
                let newOffset = start + translationWidth
                if newOffset < 0 {
                    return
                }
                if newOffset < collapsibleMenuWidth {
                    dragging = translationWidth
                } else {
                    // Resist dragging too far right
                    let springOffset = newOffset - collapsibleMenuWidth
                    dragging = collapsibleMenuWidth - start + springOffset * 0.1
                }
            }
            .onEnded { value in
                var velocity = value.velocity.width
                if layoutDirection == .rightToLeft {
                    velocity.negate()
                }
                isMenuShown = velocity >= 0
            }
    }

    var body: some View {
        GeometryReader { proxy in
            let viewportWidth = proxy.size.width
            let alwaysShowMenu = viewportWidth >= 1024
            let contentWidth = alwaysShowMenu
                ? viewportWidth - alwaysShownMenuWidth
                : viewportWidth
            let contentOffset = self.contentOffset(alwaysShowMenu: alwaysShowMenu)
            ZStack(alignment: .topLeading) {
                menu()
                content(alwaysShowMenu)
                    .shadow(radius: 7)
                    .offset(x: contentOffset)
                    .frame(maxWidth: contentWidth)
                    .animation(.interactiveSpring(extraBounce: 0), value: contentOffset)
            }
            .gesture(dragGesture, isEnabled: !alwaysShowMenu)
        }
    }
}
