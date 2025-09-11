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
                    firstName: userFirstName,
                    fullName: userFirstName, // TODO
                    viewModel: UserProfileViewModel(
                        api: api,
                        userHandle: feedViewModel.currentUserHandle,
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
        .onChange(of: feedViewModel.currentUserID) { newValue in
            guard let newValue else { return }
            Task {
                await errorObserver.runCatching {
                    let profile = try await api.send(UserProfileRequest(userID: newValue))
                    await MainActor.run {
                        // Welp, we don't have a way to get only the first name without
                        // a proper API
                        userFirstName = profile.fullName
                        userProfilePicture = profile.profilePicture
                    }
                }
            }
        }
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
                isMe: item.userHandle == feedViewModel.currentUserHandle,
                firstName: item.firstName,
                fullName: item.firstName, // TODO: Use full name
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
