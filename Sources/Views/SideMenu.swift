import SwiftUI

enum SideMenuItem: Int, Identifiable, CaseIterable {
    case profile
    case news
    case settings

    var id: Int { rawValue }

    // TODO: Make localizable
    var localizedDescription: String {
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
    @AppStorage(.palette) private var palette: Palette = .smithereen
    @State var userFullName: String
    var userProfilePicture: Image
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
                        Text(verbatim: userFullName)
                    } icon: {
                        userProfilePicture
                            .resizable()
                            .frame(width: iconSize, height: iconSize)
                            .cornerRadius(iconSize / 2)
                    }
                } else {
                    Label {
                        Text(verbatim: item.localizedDescription)
                    } icon: {
                        if let icon = item.imageResource {
                            Image(icon)
                                .foregroundStyle(palette.sideMenu.icon)
                        }
                    }
                }
            }
            .listRowBackground(
                item == selectedItem
                    ? palette.sideMenu.selectedBackground
                    : Color.clear
            )
            .listRowSeparatorTint(palette.sideMenu.separator)
        }
        .listStyle(.plain)
        .background(palette.sideMenu.background)
        .foregroundStyle(palette.sideMenu.text)
    }
}


@available(iOS 17.0, *)
#Preview("Interactive side menu") {
    @Previewable @State var selectedItem: SideMenuItem = .news
    SideMenu(
        userFullName: "Boromir",
        userProfilePicture: Image(.boromirProfilePicture),
        selectedItem: $selectedItem,
    )
    .prefireIgnored()
}

#Preview("Non-interactive side menu") {
    SideMenu(
        userFullName: "Boromir",
        userProfilePicture: Image(.boromirProfilePicture),
        selectedItem: .constant(.news)
    )
	.snapshot(perceptualPrecision: 0.96)
}
