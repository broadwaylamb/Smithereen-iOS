import SwiftUI

struct RootView: View {
    let api: any AuthenticationService & APIService
    @ObservedObject var feedViewModel: FeedViewModel

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
                    isMe: true,
                    initialFirstName: userFirstName,
                    initialFullName: userFirstName, // TODO: Use actual full name
                    viewModel: UserProfileViewModel(
                        api: api,
                        userHandle: nil, // TODO: Remove this
                        feedViewModel: feedViewModel,
                    )
                )
                .commonNavigationDestinations(api: api, feedViewModel: feedViewModel)
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
                    .commonNavigationDestinations(api: api, feedViewModel: feedViewModel)
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
        .environmentObject(errorObserver)
        .alert(errorObserver)
    }
}

extension View {
    func commonNavigationDestinations(
        api: any APIService,
        feedViewModel: FeedViewModel,
    ) -> some View {
        navigationDestinationPolyfill(
            for: UserProfileNavigationItem.self
        ) { item in
            UserProfileView(
                isMe: false, // TODO: Specify the actual value
                initialFirstName: item.firstName,
                initialFullName: item.firstName, // TODO: Use actual full name
                viewModel: UserProfileViewModel(
                    api: api,
                    userHandle: item.userHandle,
                    feedViewModel: feedViewModel,
                ),
            )
        }
    }
}

#Preview {
    let api = MockApi()
    RootView(api: api, feedViewModel: FeedViewModel(api: api))
        .environmentObject(PaletteHolder())
        .prefireIgnored()
}
