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

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        SlideableMenuView(selection: $sideMenuSelection) {
            SMSideMenuItem(value: SideMenuValue.profile) {
                UserProfileView(
                    firstName: userFirstName,
                    viewModel: UserProfileViewModel(
                        api: api,
                        userIDOrHandle: feedViewModel.currentUserID.map(Either.left),
                    )
                )
                .commonNavigationDestinations(api: api)
            } label: {
                Label {
                    Text(verbatim: userFirstName)
                } icon: {
                    UserProfilePictureView(location: userProfilePicture)
                        .frame(width: profilePictureSize, height: profilePictureSize)
                }
            }

            SMSideMenuItem("News", icon: .news, value: SideMenuValue.news) {
                FeedView(viewModel: feedViewModel)
                    .navigationTitle("News")
                    .commonNavigationDestinations(api: api)
            }

            SMSideMenuItem(
                "Settings",
                icon: .settings,
                value: SideMenuValue.settings,
                isModal: horizontalSizeClass == .regular,
            ) {
                SettingsView(api: api)
                    .navigationTitle("Settings")
            }
        } sideMenu: { rows in
            List {
                rows
            }
            .listStyle(.plain)
            .scrollContentBackgroundPolyfill(.hidden)
            .background(palette.sideMenu.background)
            .foregroundStyle(palette.sideMenu.text)
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
    func commonNavigationDestinations(api: any APIService) -> some View {
        navigationDestinationPolyfill(
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
}

private enum SideMenuValue: Hashable {
    case profile
    case news
    case settings
}

private struct SMSideMenuItem<Content: View, Label: View>: SideMenuContent {
    var value: SideMenuValue
    var isModal: Bool = false
    var content: () -> Content
    var label: () -> Label

    func identifiedView() -> Content {
        content()
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

#Preview {
    let api = MockApi()
    RootView(api: api, feedViewModel: FeedViewModel(api: api))
        .environmentObject(PaletteHolder())
        .prefireIgnored()
}
