import SwiftUI

struct RootView: View {
    let api: any AuthenticationService
    let feedViewModel: FeedViewModel

    @AppStorage(.palette) private var palette: Palette = .smithereen

    @State private var offset: CGFloat = 0
	@State private var menuShown: Bool = false
	@State private var selectedItem: SideMenuItem = .news

    @State private var previousOffset: CGFloat = 0

	private let collapsibleMenuWidth: CGFloat = 276
    private let alwaysShownMenuWidth: CGFloat = 256
	private let dragThreshold: CGFloat = 138

	private func hideMenu() {
		offset = 0
        previousOffset = offset
		menuShown = false
	}

    private func showMenu() {
		offset = collapsibleMenuWidth
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
            SettingsView(api: api)
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
                                        Image(.menu)
                                    }
                                    .tint(Color.white)
                                }
                            }
                        }
                }
                .navigationViewStyle(.stack)
                .shadow(radius: 7)
                .offset(x: alwaysShowMenu ? alwaysShownMenuWidth : offset)
                .frame(maxWidth: alwaysShowMenu ? viewportWidth - alwaysShownMenuWidth : viewportWidth)
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
                            if newOffset < collapsibleMenuWidth {
                                offset = newOffset
                            } else {
                                // Resist dragging too far right
                                let springOffset = newOffset - collapsibleMenuWidth
                                offset = collapsibleMenuWidth + springOffset * 0.3
                            }
                        } else if menuShown {
                            offset = max(value.translation.width + collapsibleMenuWidth, 0)
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
                            offset = menuShown ? collapsibleMenuWidth : 0
                            previousOffset = offset
                        }
                    }
            )
        }
	}
}

#Preview {
    let api = MockApi()
    RootView(api: api, feedViewModel: FeedViewModel(api: api))
        .prefireIgnored()
}
