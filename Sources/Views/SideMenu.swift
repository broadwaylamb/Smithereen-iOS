import SwiftUI

enum SideMenuItem: Int, Identifiable, CaseIterable {
    case profile
    case news
    case settings

    var id: Int { rawValue }

    var localizedDescription: LocalizedStringKey {
        switch self {
        case .profile:
            "Profile"
        case .news:
            "News"
        case .settings:
            "Settings"
        }
    }

    var imageResource: ImageResource? {
        switch self {
        case .profile:
            nil
        case .news:
            .news
        case .settings:
            .settings
        }
    }
}

struct SideMenu: View {
    let api: any APIService
    @ObservedObject var feedViewModel: FeedViewModel
    @Binding var userFirstName: String
    @EnvironmentObject private var errorObserver: ErrorObserver
    @EnvironmentObject private var palette: PaletteHolder
    @State private var userProfilePicture: ImageLocation?
    @Binding var selectedItem: SideMenuItem

    @ScaledMetric(relativeTo: .body)
    private var iconSize = 37

    var body: some View {
        List(SideMenuItem.allCases) { item in
            Button {
                selectedItem = item
            } label: {
                if item == .profile {
                    Label {
                        Text(verbatim: userFirstName)
                    } icon: {
                        UserProfilePictureView(location: userProfilePicture)
                            .frame(width: iconSize, height: iconSize)
                    }
                } else {
                    Label {
                        Text(item.localizedDescription)
                    } icon: {
                        if let icon = item.imageResource {
                            Image(icon)
                                .foregroundStyle(palette.sideMenu.icon)
                        }
                    }
                }
            }
            .disabled(item == .profile && feedViewModel.currentUserID == nil)
            .listRowBackground(
                item == selectedItem
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
        .listStyle(.plain)
        .scrollContentBackgroundPolyfill(.hidden)
        .background(palette.sideMenu.background)
        .foregroundStyle(palette.sideMenu.text)
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

@available(iOS 17.0, *)
#Preview("Interactive side menu") {
    @Previewable @State var selectedItem: SideMenuItem = .news
    @Previewable @State var userFirstName: String = "…"
    let api = MockApi()
    let feedViewModel = FeedViewModel(api: api)
    SideMenu(
        api: api,
        feedViewModel: feedViewModel,
        userFirstName: $userFirstName,
        selectedItem: $selectedItem,
    )
    .environmentObject(ErrorObserver())
    .environmentObject(PaletteHolder())
    .task {
        try! await feedViewModel.update()
    }
    .prefireIgnored()
}

#Preview("Non-interactive side menu") {
    let api = MockApi()
    let feedViewModel = FeedViewModel(api: api)
    SideMenu(
        api: api,
        feedViewModel: feedViewModel,
        userFirstName: .constant("Boromir"),
        selectedItem: .constant(.news),
    )
    .environmentObject(ErrorObserver())
    .environmentObject(PaletteHolder())
    .task {
        try! await feedViewModel.update()
    }
    .snapshot(perceptualPrecision: 0.96)
}
