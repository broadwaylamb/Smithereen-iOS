import SwiftUI

struct RootView: View {
    let api: any AuthenticationService & APIService
    let actorStorage: ActorStorage

    @ObservedObject var currentUserProfileViewModel: UserProfileViewModel
    @StateObject var feedViewModel: FeedViewModel

    init(
        api: any AuthenticationService & APIService,
        actorStorage: ActorStorage,
    ) {
        self.api = api
        self.actorStorage = actorStorage
        self.currentUserProfileViewModel = actorStorage.currentUserViewModel
        self._feedViewModel = StateObject(
            wrappedValue: FeedViewModel(api: api, actorStorage: actorStorage)
        )
    }

    @StateObject private var errorObserver = ErrorObserver()

    @ScaledMetric(relativeTo: .body)
    private var profilePictureSize = 37

    @State private var userFirstName: String = "…"
    @State private var userProfilePicture: ImageLocation?

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        SMSlideableMenuView {
            SMSideMenuItem(value: .profile) {
                UserProfileView(
                    viewModel: currentUserProfileViewModel,
                )
                .commonNavigationDestinations(
                    api: api,
                    actorStorage: actorStorage,
                    feedViewModel: feedViewModel,
                )
            } label: {
                Label {
                    Text(verbatim: userFirstName)
                } icon: {
                    UserProfilePictureView(location: userProfilePicture)
                        .frame(width: profilePictureSize, height: profilePictureSize)
                }
            }

            SMSideMenuItem("News", icon: .news, value: .news) {
                FeedView(viewModel: feedViewModel)
                    .navigationTitle("News")
                    .commonNavigationDestinations(
                        api: api,
                        actorStorage: actorStorage,
                        feedViewModel: feedViewModel,
                    )
            }

            SMSideMenuItem(
                "Settings",
                icon: .settings,
                value: .settings,
                isModal: horizontalSizeClass == .regular,
            ) {
                SettingsView(api: api)
                    .navigationTitle("Settings")
            }
        }
        .task {
            await errorObserver.runCatching {
                try await currentUserProfileViewModel.loadProfile()
            }
        }
        .environmentObject(errorObserver)
        .alert(errorObserver)
    }
}

extension View {
    func commonNavigationDestinations(
        api: APIService,
        actorStorage: ActorStorage,
        feedViewModel: FeedViewModel,
    ) -> some View {
        navigationDestinationPolyfill(for: UserProfileNavigationItem.self) { item in
            UserProfileView(viewModel: actorStorage.getUser(item.userID))
        }
    }
}

#Preview {
    let api = MockApi()
    RootView(
        api: api,
        actorStorage: ActorStorage(api: api, currentUserID: .init(rawValue: 1)),
    )
    .environmentObject(PaletteHolder())
    .prefireIgnored()
}
