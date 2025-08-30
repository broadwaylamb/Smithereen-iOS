import SwiftUI
import SlideableMenu

struct SMSlideableMenuView<Rows, Content>: View {
    @SlideableMenuContentBuilder<SideMenuValue> var items:
        () -> SlideableMenuContentBuilder<SideMenuValue>.Result<Rows, Content>

    @State private var selection: SideMenuValue = .news

    @EnvironmentObject private var palette: PaletteHolder

    var body: some View {
        GeometryReader { proxy in
            let alwaysShowMenu = proxy.size.width >= 1024
            SlideableMenuView(selection: $selection, items) { rows in
                List {
                    rows
                }
                .listStyle(.plain)
                .scrollContentBackgroundPolyfill(.hidden)
                .background(palette.sideMenu.background)
                .foregroundStyle(palette.sideMenu.text)
            }
            .fixSlideableMenu(alwaysShowMenu)
            .slideableMenuWidth(alwaysShowMenu ? 256 : 276)
        }
    }
}

enum SideMenuValue: Hashable {
    case profile
    case news
    case settings
}

private struct SideMenuRow<Label: View>: View {
    fileprivate var value: SideMenuValue
    var isModal: Bool
    @Binding var isSelected: Bool
    var label: () -> Label

    @EnvironmentObject private var palette: PaletteHolder

    @ScaledMetric(relativeTo: .body)
    private var iconSize = 37

    var body: some View {
        Button(action: { isSelected = true }, label: label)
            .listRowBackground(
                isSelected
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

struct SMSideMenuItem<Content: View, Label: View>: SlideableMenuContent {
    var value: SideMenuValue
    var isModal: Bool = false
    var content: () -> Content
    var label: () -> Label

    func identifiedView() -> some View {
        SMNavigationStack {
            content()
        }
        .shadow(radius: 7)
    }

    func labelView(isSelected: Binding<Bool>) -> some View {
        SideMenuRow(value: value, isModal: isModal, isSelected: isSelected, label: label)
    }
}

extension SMSideMenuItem where Label == SwiftUI.Label<Text, Image> {
    init(
        _ title: LocalizedStringKey,
        icon: ImageResource,
        value: SideMenuValue,
        isModal: Bool = false,
        @ViewBuilder content: @MainActor @escaping () -> Content,
    ) {
        self.init(value: value, isModal: isModal, content: content) {
            Label {
                Text(title)
            } icon: {
                Image(icon)
            }
        }
    }
}
