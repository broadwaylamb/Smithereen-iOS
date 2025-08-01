import SwiftUI

private let collapsibleMenuWidth: CGFloat = 276
private let alwaysShownMenuWidth: CGFloat = 256

private let defaultIconSize: CGFloat = 37

struct SideMenuRow<Value: Hashable, Label: View>: View {
    fileprivate var value: Value
    fileprivate var label: () -> Label

    @EnvironmentObject private var viewModel: SideMenuViewModel<Value>
    @EnvironmentObject private var palette: PaletteHolder

    @ScaledMetric(relativeTo: .body)
    private var iconSize = defaultIconSize

    var body: some View {
        Button(action: { viewModel.selectItem(value) }, label: label)
            .listRowBackground(
                viewModel.selection == value
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

struct SlideableMenuView<Value: Hashable, Rows, Content>: View {
    @StateObject private var viewModel: SideMenuViewModel<Value>
    private let rows: Rows
    private let content: Content

    init(
        selection: Binding<Value>,
        @SideMenuContentBuilder<Value> _ items: () -> SideMenuContentBuilderResult<
            Value, Rows, Content
        >
    ) {
        let result = items()
        _viewModel = StateObject(
            wrappedValue: SideMenuViewModel(indices: result.indices, selection: selection)
        )
        rows = result.labelTuple
        content = result.contentTuple
    }

    @Environment(\.layoutDirection) private var layoutDirection

    @GestureState private var delta: CGFloat = 0

    private func currentView() -> some View {
        ExtractSubviews(from: TupleView(content)) { children in
            SMNavigationStack(path: $viewModel.navigationPath) {
                children[viewModel.currentViewIndex]
            }
        }
        .id(viewModel.selection)
    }

    private var start: CGFloat {
        viewModel.isMenuShown ? collapsibleMenuWidth : 0
    }

    private func contentOffset(alwaysShowMenu: Bool) -> CGFloat {
        if alwaysShowMenu {
            return alwaysShownMenuWidth
        }
        if !viewModel.navigationPath.isEmpty && !viewModel.isMenuShown && delta < 25 {
            // Prevent conflicting with the native "swipe back from left edge"
            // gesture.
            return start
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
                currentView()
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
protocol SideMenuContent<Value> {
    associatedtype Value: Hashable
    associatedtype IdentifiedView: View
    associatedtype Label: View

    var value: Value { get }

    func identifiedView() -> IdentifiedView

    func labelView() -> Label
}

struct SideMenuItem<Value: Hashable, Content: View, Label: View>: SideMenuContent {
    var value: Value
    @ViewBuilder var content: @MainActor () -> Content
    @ViewBuilder var label: @MainActor () -> Label

    func identifiedView() -> Content {
        content()
    }

    func labelView() -> Label {
        label()
    }
}

extension SideMenuItem where Label == SwiftUI.Label<Text, Image> {
    init(
        _ title: LocalizedStringKey,
        icon: ImageResource,
        value: Value,
        @ViewBuilder content: @MainActor @escaping () -> Content,
    ) {
        self.init(value: value, content: content) {
            SwiftUI.Label {
                Text(title)
            } icon: {
                Image(icon)
            }
        }
    }
}

struct SideMenuContentBuilderResult<Value: Hashable, RowTuple, ContentTuple> {
    fileprivate let indices: [Value : Int]
    fileprivate let labelTuple: RowTuple
    fileprivate let contentTuple: ContentTuple
}

@resultBuilder
struct SideMenuContentBuilder<Value: Hashable> {

    // FIXME: Uncomment <Value> when same-type requirements are supported for
    // type parameter packs
    // https://forums.swift.org/t/variadic-types-same-element-requirements-are-not-yet-supported
    @MainActor
    static func buildBlock<each T: SideMenuContent/*<Value>*/>(
        _ content: repeat each T,
    ) -> SideMenuContentBuilderResult<
        Value,
        (repeat SideMenuRow<(each T).Value ,(each T).Label>),
        (repeat (each T).IdentifiedView)
    > {
        var indices = [Value : Int]()
        var i = 0
        for c in repeat each content {
            indices[c.value as! Value] = i
            i += 1
        }

        return SideMenuContentBuilderResult(
            indices: indices,
            labelTuple: (
                repeat SideMenuRow(
                    value: (each content).value,
                    label: (each content).labelView
                ),
            ),
            contentTuple: (
                repeat (each content).identifiedView()
            ),
        )
    }
}

private final class SideMenuViewModel<Value: Hashable>: ObservableObject {
    let indices: [Value : Int]
    @Published var isMenuShown = false
    @Published var navigationPath = NavigationPath()
    @Binding private(set) var selection: Value
    @Published private(set) var currentViewIndex: Int

    init(indices: [Value : Int], selection: Binding<Value>) {
        self.indices = indices
        _selection = selection
        currentViewIndex = indices[selection.wrappedValue] ?? 0
    }

    func selectItem(_ newSelection: Value) {
        isMenuShown = false
        selection = newSelection
        currentViewIndex = indices[newSelection] ?? 0
        navigationPath.removeAll()
    }
}
