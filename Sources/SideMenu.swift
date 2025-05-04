import SwiftUI

enum SideMenuItem: Int, Identifiable, CaseIterable {
	case profile
	case news
	case feedback
	case messages
	case friends
	case groups
	case photos
	case bookmarks
	case settings
	
	var id: Int { rawValue }
	
	// TODO: Make localizable
	var localizedDescription: String {
		switch self {
		case .profile:
			"Profile"
		case .news:
			"News"
		case .feedback:
			"Feedback"
		case .messages:
			"Messages"
		case .friends:
			"Friends"
		case .groups:
			"Groups"
		case .photos:
			"Photos"
		case .bookmarks:
			"Bookmarks"
		case .settings:
			"Settings"
		}
	}
	
	var sfSymbolsIconName: String? {
		switch self {
		case .profile:
			nil
		case .news:
			"message"
		case .feedback:
			"bubble.left.and.bubble.right"
		case .messages:
			"envelope"
		case .friends:
			"person"
		case .groups:
			"person.2"
		case .photos:
			"rectangle.on.rectangle"
		case .bookmarks:
			"star"
		case .settings:
			"gear"
		}
	}
}

struct SideMenuRow: View {
	var icon: Image
	var text: String
	var isSelected: Bool

    @ScaledMetric(relativeTo: .body)
    private var iconSize = 37

	var body: some View {
        HStack {
			icon
				.frame(width: iconSize, height: iconSize)
				.cornerRadius(iconSize / 2)
				.foregroundStyle(Color.SideMenu.icon)
			Text(verbatim: text)
			Spacer()
		}
		.listRowBackground(isSelected ? Color.SideMenu.selectedBackground : Color.clear)
		.listRowSeparatorTint(Color.SideMenu.separator)
		.listRowInsets(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 0))
	}
}

struct SideMenu: View {
	var userFullName: String
	var userProfilePicture: Image
	@Binding var selectedItem: SideMenuItem
	
	var body: some View {
		List(SideMenuItem.allCases) { item in
			let isSelected = item == selectedItem
			let row = if item == .profile {
				SideMenuRow(icon: userProfilePicture.resizable(), text: userFullName, isSelected: isSelected)
			} else {
				SideMenuRow(
					icon: Image(systemName: item.sfSymbolsIconName!),
					text: item.localizedDescription,
					isSelected: isSelected,
				)
			}
			row.onTapGesture {
				selectedItem = item
			}
		}
		.listStyle(.plain)
		.background(Color.SideMenu.background)
		.foregroundStyle(Color.SideMenu.text)
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
}
