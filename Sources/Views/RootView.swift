import SwiftUI

struct RootView: View {
    let api: any AuthenticationService & APIService
    let feedViewModel: FeedViewModel

    @EnvironmentObject private var palette: PaletteHolder

    @StateObject private var errorObserver = ErrorObserver()

    @State private var menuShown: Bool = false
    @State private var selectedItem: SideMenuItem = .news

    @State private var userFirstName: String = "…"

    @ViewBuilder
    private var mainView: some View {
        switch selectedItem {
        case .news:
            FeedView(viewModel: feedViewModel)
        case .settings:
            SettingsView(api: api)
        default:
            UserProfileView(
                firstName: userFirstName,
                viewModel: UserProfileViewModel(
                    api: api,
                    userIDOrHandle: .left(feedViewModel.currentUserID!)
                )
            )
        }
    }

    var body: some View {
        SlideableMenuView(isMenuShown: $menuShown) {
            SideMenu(
                api: api,
                feedViewModel: feedViewModel,
                userFirstName: $userFirstName,
                selectedItem: $selectedItem
            )
        } content: { alwaysShowMenu in
            NavigationView {
                mainView
                    .navigationBarStyleSmithereen()
                    .navigationTitle(selectedItem.localizedDescription)
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
        .environmentObject(PaletteHolder())
        .prefireIgnored()
}
