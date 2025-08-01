import SwiftUI

private let collapsibleMenuWidth: CGFloat = 276
private let alwaysShownMenuWidth: CGFloat = 256

private let defaultIconSize: CGFloat = 37

private struct SideMenuItem<Title: View, Icon: View>: View {
    @Binding var active: Bool
    @ViewBuilder var title: () -> Title
    @ViewBuilder var icon: () -> Icon

    @EnvironmentObject private var palette: PaletteHolder

    @ScaledMetric(relativeTo: .body)
    private var iconSize = defaultIconSize

    var body: some View {
        Button {
            active = true
        } label: {
            Label(title: title) {
                icon()
                    .foregroundStyle(palette.sideMenu.icon)
                    .frame(width: iconSize, height: iconSize)
            }
        }
        .listRowBackground(
            active
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

struct ModalSideMenuItem<Title: View, Icon: View, ModalView: View>: View {
    @ViewBuilder var title: () -> Title
    @ViewBuilder var icon: () -> Icon
    @ViewBuilder var modalView: () -> ModalView

    @State private var shown = false

    var body: some View {
        SideMenuItem(active: $shown, title: title, icon: icon)
            .sheet(isPresented: $shown) {
                SmithereenNavigationView(content: modalView)
            }
    }
}

extension ModalSideMenuItem where Title == Text, Icon == Image {
    init(
        _ title: LocalizedStringKey,
        image: ImageResource,
        @ViewBuilder modalView: @escaping () -> ModalView,
    ) {
        self.init(title: { Text(title) }, icon: { Image(image) }, modalView: modalView)
    }
}

struct NonModalSideMenuItem<Title: View, Icon: View, Content: View>: View {
    @ViewBuilder var title: () -> Title
    @ViewBuilder var icon: () -> Icon
    @ViewBuilder var content: () -> Content

    @State private var active = false

    @State private var menuShown = false

    @EnvironmentObject private var sideMenuShownState: SideMenuViewModel

    var body: some View {
        SideMenuItem(active: $active, title: title, icon: icon)
            .slideableMenuContent { alwaysShowMenu in
                SmithereenNavigationView {
                    content()
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                if !alwaysShowMenu {
                                    Button {
                                        sideMenuShownState.isMenuShown.toggle()
                                    } label: {
                                        Image(.menu)
                                    }
                                }
                            }
                        }
                }
            }
    }
}

extension NonModalSideMenuItem where Title == Text, Icon == Image {
    init(
        _ title: LocalizedStringKey,
        image: ImageResource,
        @ViewBuilder content: @escaping () -> Content,
    ) {
        self.init(title: { Text(title) }, icon: { Image(image) }, content: content)
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

struct SlideableMenuView<MenuItems: View>: View {
    @StateObject private var menuShownState = SideMenuViewModel()

    @ViewBuilder
    var menuItems: () -> MenuItems

    @Environment(\.layoutDirection) private var layoutDirection

    @GestureState private var delta: CGFloat = 0

    @State private var currentContentID: Int = -1
    @State private var contentViews: [Int : (Bool) -> AnyView] = [:]

    private func currentView(alwaysShowMenu: Bool) -> AnyView {
        contentViews[currentContentID]?(alwaysShowMenu) ?? AnyView(EmptyView())
    }

    private var start: CGFloat {
        menuShownState.isMenuShown ? collapsibleMenuWidth : 0
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
                menuShownState.isMenuShown = velocity >= 0
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
                SideMenu(content: menuItems)
                    .environmentObject(SideMenuViewModel())
                currentView(alwaysShowMenu: alwaysShowMenu)
                    .shadow(radius: 7)
                    .overlay {
                        if menuShownState.isMenuShown {
                            Color.black.opacity(0.0001)
                                .ignoresSafeArea()
                                .onTapGesture {
                                    menuShownState.isMenuShown = false
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

private struct CurrentlySelectedViewIDKey: PreferenceKey {
    typealias Value = Int
    static let defaultValue = -1
    static func reduce(value: inout Int, nextValue: () -> Int) {
        value = nextValue()
    }
}

extension View {
    
}

private struct SlideableMenuContentPreferenceKey: PreferenceKey {
    struct Value: Identifiable, Equatable {
        let id: Int
        let makeView: @MainActor (Bool) -> AnyView

        static func == (lhs: Value, rhs: Value) -> Bool {
            lhs.id == rhs.id
        }
    }

    static let defaultValue = Value(id: -1) { _ in AnyView(EmptyView()) }

    static func reduce(value: inout Value, nextValue: () -> Value) {
        value = nextValue()
    }
}

@MainActor
private var sideMenuItemID = 0

extension View {
    fileprivate func slideableMenuContent<V: View>(
        _ content: @escaping @MainActor (_ alwaysShowMenu: Bool) -> V,
    ) -> some View {
        let id = sideMenuItemID
        sideMenuItemID += 1
        return preference(
            key: SlideableMenuContentPreferenceKey.self,
            value: SlideableMenuContentPreferenceKey
                .Value(id: id) { AnyView(content($0)) },
        )
    }
}

private final class SideMenuViewModel: ObservableObject {
    @Published var isMenuShown = false
}
