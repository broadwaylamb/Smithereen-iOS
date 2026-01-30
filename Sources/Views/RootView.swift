import SwiftUI

struct RootView: View {
    let api: any AuthenticationService & APIService
    let db: SmithereenDatabase

    @StateObject var viewModel: RootViewModel

    init(
        api: any AuthenticationService & APIService,
        db: SmithereenDatabase,
    ) {
        self.api = api
        self.db = db
        self._viewModel = StateObject(wrappedValue: RootViewModel(api: api, db: db))
    }

    @StateObject private var errorObserver = ErrorObserver()

    @ScaledMetric(relativeTo: .body)
    private var profilePictureSize = 37

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @ViewBuilder
    private func profilePictureView() -> some View {
        if let sizes = viewModel.profilePictureSizes {
            UserProfilePictureView(sizes: sizes)
        } else {
            Color.clear
        }
    }

    var body: some View {
        SMSlideableMenuView {
            SMSideMenuItem(value: .profile) {
                UserProfileView(userID: nil, api: api, db: db)
                    .commonNavigationDestinations(api: api, db: db)
            } label: {
                Label {
                    Text(verbatim: viewModel.profileRowTitle)
                } icon: {
                    profilePictureView()
                        .frame(width: profilePictureSize, height: profilePictureSize)
                }
            }

            SMSideMenuItem("News", icon: .news, value: .news) {
                FeedView(viewModel: viewModel.feedViewModel)
                    .navigationTitle("News")
                    .commonNavigationDestinations(
                        api: api,
                        db: db,
                    )
            }

            SMSideMenuItem(
                "Settings",
                icon: .settings,
                value: .settings,
                isModal: horizontalSizeClass == .regular,
            ) {
                SettingsView(api: api, db: db)
                    .navigationTitle("Settings")
            }
        }
        .task {
            await errorObserver.runCatching {
                try await viewModel.load()
            }
        }
        .environmentObject(errorObserver)
        .alert(errorObserver)
    }
}

extension View {
    func commonNavigationDestinations(
        api: APIService,
        db: SmithereenDatabase,
    ) -> some View {
        navigationDestinationPolyfill(for: UserProfileNavigationItem.self) { item in
            UserProfileView(userID: item.userID, api: api, db: db)
        }
    }
}

#Preview {
    let api = MockApi()
    RootView(
        api: api,
        db: try! .createInMemory(),
    )
    .environmentObject(PaletteHolder())
    .prefireIgnored()
}
