import SwiftUI

struct RootView: View {
    let api: any AuthenticationService
    let feedViewModel: FeedViewModel

    @EnvironmentObject private var palette: PaletteHolder

    @StateObject private var errorObserver = ErrorObserver()

    @State private var menuShown: Bool = false
    @State private var selectedItem: SideMenuItem = .news

    @ViewBuilder
    private var mainView: some View {
        switch selectedItem {
        case .news:
            FeedView(viewModel: feedViewModel)
        case .settings:
            SettingsView(api: api)
        default:
            Text("Coming soon!").font(.largeTitle)
        }
    }

    var body: some View {
        SlideableMenuView(isMenuShown: $menuShown) {
            SideMenu(
                userFullName: "Boromir",
                userProfilePicture: .bundled(.boromirProfilePicture),
                selectedItem: $selectedItem
            )
        } content: { alwaysShowMenu in
            NavigationView {
                mainView
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationTitle(selectedItem.localizedDescription)
                    .navigationBarBackground(palette.accent)
                    .navigationBarBackground(.visible)
                    .navigationBarColorScheme(.dark)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            if !alwaysShowMenu {
                                Button(action: { menuShown.toggle() }) {
                                    Image(.menu)
                                }
                                .tint(Color.white)
                            }
                        }
                    }
            }
            .navigationViewStyle(.stack)
            .navigationBarBackground(palette.accent)
            .navigationBarBackground(.visible)
            .navigationBarColorScheme(.dark)
            .onChange(of: selectedItem) { _ in
                // TODO: Hide the menu not only on change, but on any tap on a menu item.
                menuShown = false
            }
            .preferredColorScheme(.dark)
        }
        .environmentObject(errorObserver)
        .alert(errorObserver)
    }
}

#Preview {
    let api = MockApi()
    RootView(api: api, feedViewModel: FeedViewModel(api: api))
        .prefireIgnored()
}
