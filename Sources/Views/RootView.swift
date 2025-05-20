import SwiftUI

struct RootView: View {
    let feedViewModel: FeedViewModel

    @Environment(\.palette) private var palette

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

    @ViewBuilder
	private var mainView: some View {
		switch selectedItem {
		case .news:
			FeedView(viewModel: feedViewModel)
        case .settings:
            SettingsView()
		default:
            Text("Coming soon!").font(.largeTitle)
		}
	}

	var body: some View {
        GeometryReader { proxy in
            let viewportWidth = proxy.size.width
            let alwaysShowMenu = viewportWidth >= 1024
            ZStack(alignment: .topLeading) {
                SideMenu(
                    userFullName: "Boromir",
                    userProfilePicture: Image(.boromirProfilePicture),
                    selectedItem: $selectedItem
                )
                NavigationView {
                    mainView
                        .navigationBarTitleDisplayMode(.inline)
                        .navigationTitle(selectedItem.localizedDescription)
                        .navigationBarBackground(palette.accent)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                if !alwaysShowMenu {
                                    Button(action: toggleMenu) {
                                        Image(systemName: "list.bullet")
                                    }
                                    .tint(Color.white)
                                }
                            }
                        }
                }
                .navigationViewStyle(.stack)
                .shadow(radius: 7)
                .offset(x: alwaysShowMenu ? menuWidth : offset)
                .frame(maxWidth: alwaysShowMenu ? viewportWidth - menuWidth : viewportWidth)
                .animation(.interactiveSpring(extraBounce: 0), value: offset)
                .onChangePolyfill(of: selectedItem, hideMenu)
                .preferredColorScheme(.dark)
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let newOffset = previousOffset + value.translation.width
                        if alwaysShowMenu {
                            // Do nothing
                        } else if value.translation.width > 0 {
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
                        if alwaysShowMenu {
                            // Do nothing
                        } else if value.translation.width > dragThreshold {
                            showMenu()
                        } else if -value.translation.width > dragThreshold && menuShown {
                            hideMenu()
                        } else {
                            offset = menuShown ? menuWidth : 0
                            previousOffset = offset
                        }
                    }
            )
        }
	}
}

#Preview {
    RootView(feedViewModel: FeedViewModel(api: MockApi()))
        .prefireIgnored()
}
