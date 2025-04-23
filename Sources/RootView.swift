import SwiftUI
import SwiftData

struct RootView: View {
	var viewportWidth: CGFloat
	@State private var offset: CGFloat = 0
	@State private var menuShown: Bool = false
	@State private var selectedItem: SideMenuItem = .news

    @State private var previousOffset: CGFloat = 0

	private let menuWidth: CGFloat = 256
	private let dragThreshold: CGFloat = 128

	private func hideMenu() {
		offset = 0
        previousOffset = offset
		menuShown = false
	}

	private func showMenu() {
		offset = menuWidth
        previousOffset = offset
		menuShown = true
	}

	private func toggleMenu() {
		menuShown ? hideMenu() : showMenu()
	}

	private var alwaysShowMenu: Bool {
		viewportWidth >= 1024
	}

	private var mainView: some View {
		switch selectedItem {
		case .news:
			AnyView(FeedView())
		default:
			AnyView(Text("TODO").background(Color.background))
		}
	}

	var body: some View {
		ZStack {
			SideMenu(
				userFullName: "Boromir",
				userProfilePicture: Image(.userProfilePicture),
				selectedItem: $selectedItem
			)
			NavigationView {
				mainView
					.navigationBarTitleDisplayMode(.inline)
					.navigationTitle(selectedItem.localizedDescription)
					.navigationBarBackground(.accent)
					.toolbar {
						ToolbarItem(placement: .navigationBarLeading) {
							Button(action: toggleMenu) {
								Image(systemName: "list.bullet")
							}
						}
					}
			}
			.navigationViewStyle(.stack)
			.shadow(radius: 7)
			.offset(x: alwaysShowMenu ? menuWidth : offset)
			.frame(maxWidth: alwaysShowMenu ? viewportWidth - menuWidth : viewportWidth)
			.animation(.interactiveSpring(extraBounce: 0), value: offset)
			.gesture(
				DragGesture()
					.onChanged { value in
                        let newOffset = previousOffset + value.translation.width
						if value.translation.width > 0 {
                            if newOffset < menuWidth {
                                offset = newOffset
                            } else {
                                // Resist dragging too far right
                                let springOffset = newOffset - menuWidth
                                offset = menuWidth + springOffset * 0.3
                            }
						} else if menuShown {
							offset = max(value.translation.width + menuWidth, 0)
						}

					}
					.onEnded { value in
						if value.translation.width > dragThreshold {
							showMenu()
						} else if -value.translation.width > dragThreshold && menuShown {
							hideMenu()
						} else {
							offset = menuShown ? menuWidth : 0
                            previousOffset = offset
						}
					}
			)
			.onChangePolyfill(of: selectedItem, hideMenu)
		}
	}
}

#Preview {
	GeometryReader { proxy in
		RootView(viewportWidth: proxy.size.width)
	}
}
