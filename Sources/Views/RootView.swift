import SwiftUI

struct RootView: View {
    let api: any AuthenticationService
    let feedViewModel: FeedViewModel

    @EnvironmentObject private var palette: PaletteHolder

    @StateObject private var errorObserver = ErrorObserver()

    var body: some View {
        SlideableMenuView {
            NonModalSideMenuItem {
                Text(verbatim: "Boromir")
            } icon: {
                UserProfilePictureView(location: .bundled(.boromirProfilePicture))
            } content: {
                Text("Coming soon!").font(.largeTitle)
            }

            NonModalSideMenuItem("News", image: .news) {
                FeedView(viewModel: feedViewModel)
                    .navigationTitle("News")
            }

            ModalSideMenuItem("Settings", image: .settings) {
                SettingsView(api: api)
                    .navigationTitle("Settings")
            }
        }
        .environmentObject(errorObserver)
        .alert(errorObserver)
    }
}

#Preview {
    let api = MockApi()
    RootView(api: api, feedViewModel: FeedViewModel(api: api))
        .environmentObject(PaletteHolder())
        .prefireIgnored()
}
