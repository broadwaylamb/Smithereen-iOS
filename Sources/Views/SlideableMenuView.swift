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

    @State private var offset: CGFloat = 0

    @State private var previousOffset: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            let viewportWidth = proxy.size.width
            let alwaysShowMenu = viewportWidth >= 1024
            let contentWidth = alwaysShowMenu
                ? viewportWidth - alwaysShownMenuWidth
                : viewportWidth
            ZStack(alignment: .topLeading) {
                menu()
                content(alwaysShowMenu)
                    .shadow(radius: 7)
                    .offset(x: alwaysShowMenu ? alwaysShownMenuWidth : offset)
                    .frame(maxWidth: contentWidth)
                    .animation(.interactiveSpring(extraBounce: 0), value: offset)
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        var translationWidth = value.translation.width
                        if layoutDirection == .rightToLeft {
                            translationWidth.negate()
                        }
                        let newOffset = previousOffset + translationWidth
                        if alwaysShowMenu {
                            // Do nothing
                        } else if translationWidth > 0 {
                            if newOffset < collapsibleMenuWidth {
                                offset = newOffset
                            } else {
                                // Resist dragging too far right
                                let springOffset = newOffset - collapsibleMenuWidth
                                offset = collapsibleMenuWidth + springOffset * 0.3
                            }
                        } else if isMenuShown {
                            offset = max(translationWidth + collapsibleMenuWidth, 0)
                        }

                    }
                    .onEnded { value in
                        var translationWidth = value.translation.width
                        if layoutDirection == .rightToLeft {
                            translationWidth.negate()
                        }
                        if alwaysShowMenu {
                            // Do nothing
                        } else if translationWidth > dragThreshold {
                            isMenuShown = true
                        } else if -translationWidth > dragThreshold && isMenuShown {
                            isMenuShown = false
                        } else {
                            offset = isMenuShown ? collapsibleMenuWidth : 0
                            previousOffset = offset
                        }
                    }
            )
        }
        .onChange(of: isMenuShown) { isMenuShown in
            if isMenuShown {
                offset = collapsibleMenuWidth
                previousOffset = offset
            } else {
                offset = 0
                previousOffset = offset
            }
        }
    }
}
