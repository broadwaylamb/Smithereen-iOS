import SwiftUI

private let collapsibleMenuWidth: CGFloat = 276
private let alwaysShownMenuWidth: CGFloat = 256

private let defaultIconSize: CGFloat = 37

struct SideMenuRow<Label: View>: View {
    fileprivate var index: Int
    fileprivate var label: () -> Label

    @EnvironmentObject private var viewModel: SideMenuViewModel
    @EnvironmentObject private var palette: PaletteHolder

    @ScaledMetric(relativeTo: .body)
    private var iconSize = defaultIconSize

    var body: some View {
        Button(
            action: {
                print("Index: \(index)")
                viewModel.isMenuShown = false
                viewModel.currentViewIndex = index
            },
            label: label,
        )
        .listRowBackground(
            viewModel.currentViewIndex == index
                ? palette.sideMenu.selectedBackground
                : Color.clear
        )
        .listRowSeparator(.hidden, edges: .top)
        .listRowSeparatorTint(palette.sideMenu.separator)
        .introspect(.listCell, on: .iOS(.v15)) { cell in
            // Before iOS 16 cell separators are not aligned to the first text label
            cell.separatorInset.left = iconSize
        }
    }
}

private struct SideMenu<Content: View>: View {
    @ViewBuilder var content: () -> Content
    @EnvironmentObject private var palette: PaletteHolder

    var body: some View {
        List(content: content)
            .listStyle(.plain)
            .scrollContentBackgroundPolyfill(.hidden)
            .background(palette.sideMenu.background)
            .foregroundStyle(palette.sideMenu.text)
    }
}

struct SlideableMenuView<Rows>: View {
    private let rows: Rows
    private let identifiedViews: [@MainActor () -> AnyView]

    init(@SideMenuContentBuilder _ items: () -> SideMenuContentBuilderResult<Rows>) {
        let result = items()
        rows = result.labelTuple
        identifiedViews = result.identifiedViews
    }

    @StateObject private var viewModel = SideMenuViewModel()

    @Environment(\.layoutDirection) private var layoutDirection

    @GestureState private var delta: CGFloat = 0

    private func currentView(alwaysShowMenu: Bool) -> some View {
        identifiedViews[viewModel.currentViewIndex]()
    }

    private var start: CGFloat {
        viewModel.isMenuShown ? collapsibleMenuWidth : 0
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
                viewModel.isMenuShown = velocity >= 0
            }
    }

    var body: some View {
        let _ = Self._printChanges()
        GeometryReader { proxy in
            let viewportWidth = proxy.size.width
            let alwaysShowMenu = viewportWidth >= 1024
            let contentWidth = alwaysShowMenu
                ? viewportWidth - alwaysShownMenuWidth
                : viewportWidth
            let contentOffset = self.contentOffset(alwaysShowMenu: alwaysShowMenu)
            ZStack(alignment: .topLeading) {
                SideMenu(content: { TupleView(rows) })
                    .environmentObject(viewModel)
                SmithereenNavigationView {
                    currentView(alwaysShowMenu: alwaysShowMenu)
                }
                .shadow(radius: 7)
                .overlay {
                    if viewModel.isMenuShown {
                        Color.black.opacity(0.0001)
                            .ignoresSafeArea()
                            .onTapGesture {
                                viewModel.isMenuShown = false
                            }
                    }
                }
                .offset(x: contentOffset)
                .frame(maxWidth: contentWidth)
                .animation(.interactiveSpring(extraBounce: 0), value: contentOffset)
            }
            .gesture(dragGesture, isEnabled: !alwaysShowMenu)
        }
    }
}

@MainActor
protocol SideMenuContent {
    associatedtype IdentifiedView: View
    associatedtype Label: View

    var identifiedView: IdentifiedView { get }

    var labelView: Label { get }
}

struct SideMenuItem<Content: View, Label: View>: SideMenuContent {
    @ViewBuilder var content: @MainActor () -> Content
    @ViewBuilder var label: @MainActor () -> Label

    var identifiedView: Content {
        content()
    }

    var labelView: Label {
        label()
    }
}

struct SideMenuContentBuilderResult<RowTuple> {
    fileprivate let labelTuple: RowTuple
    fileprivate let identifiedViews: [@MainActor () -> AnyView]
}

@resultBuilder
struct SideMenuContentBuilder {
    @MainActor
    static func buildBlock<each T: SideMenuContent>(
        _ content: repeat each T,
    ) -> SideMenuContentBuilderResult<(repeat SideMenuRow<(each T).Label>)> {
        var id = 0
        func nextIndex() -> Int {
            defer { id += 1 }
            return id
        }
        let rows = (
            repeat SideMenuRow(
                index: nextIndex(),
                label: { (each content).labelView }),
        )

        var identifiedViews = [@MainActor () -> AnyView]()
        for identifiedView in repeat (each content).identifiedView {
            identifiedViews.append({ AnyView(identifiedView) })
        }

        return SideMenuContentBuilderResult(
            labelTuple: rows,
            identifiedViews: identifiedViews,
        )
    }
}

private final class SideMenuViewModel: ObservableObject {
    @Published var isMenuShown = false
    @Published var currentViewIndex = 0
}
