import SwiftUI

struct RootView: View {
    let api: any AuthenticationService & APIService
    @ObservedObject var feedViewModel: FeedViewModel

    @EnvironmentObject private var palette: PaletteHolder

    @StateObject private var errorObserver = ErrorObserver()

    @ScaledMetric(relativeTo: .body)
    private var profilePictureSize = 37

    @State private var userFirstName: String = "…"
    @State private var userProfilePicture: ImageLocation?

    @State private var sideMenuSelection: SideMenuValue = .news

    var body: some View {
        SlideableMenuView(selection: $sideMenuSelection) {
            SideMenuItem(value: SideMenuValue.profile) {
                UserProfileView(
                    firstName: userFirstName,
                    viewModel: UserProfileViewModel(
                        api: api,
                        userIDOrHandle: feedViewModel.currentUserID.map(Either.left),
                    )
                )
            } label: {
                Label {
                    Text(verbatim: userFirstName)
                } icon: {
                    UserProfilePictureView(location: userProfilePicture)
                        .frame(width: profilePictureSize, height: profilePictureSize)
                }
            }

            SideMenuItem("News", icon: .news, value: SideMenuValue.news) {
                FeedView(viewModel: feedViewModel)
                    .navigationTitle("News")
                    // TODO: Factor this out, this is not feed-specific
                    .navigationDestinationPolyfill(
                        for: UserProfileNavigationItem.self
                    ) { item in
                        UserProfileView(
                            firstName: item.firstName,
                            viewModel: UserProfileViewModel(
                                api: api,
                                userIDOrHandle: item.userIDOrHandle,
                            ),
                        )
                    }
            }

            SideMenuItem("Settings", icon: .settings, value: SideMenuValue.settings) {
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

private enum SideMenuValue: Hashable {
    case profile
    case news
    case settings
}

#Preview {
    let api = MockApi()
    RootView(api: api, feedViewModel: FeedViewModel(api: api))
        .environmentObject(PaletteHolder())
        .prefireIgnored()
}
