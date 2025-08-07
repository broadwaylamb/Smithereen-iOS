import SwiftUI

struct RootView: View {
    let api: any AuthenticationService
    let feedViewModel: FeedViewModel

    @EnvironmentObject private var palette: PaletteHolder

    @StateObject private var errorObserver = ErrorObserver()

    @ScaledMetric(relativeTo: .body)
    private var profilePictureSize = 37

    var body: some View {
        SlideableMenuView {
            SideMenuItem {
                Text("Coming soon!").font(.largeTitle)
            } label: {
                Label {
                    Text(verbatim: "Boromir")
                } icon: {
                    UserProfilePictureView(location: .bundled(.boromirProfilePicture))
                        .frame(width: profilePictureSize, height: profilePictureSize)
                }
            }

//            SideMenuItem {
//                FeedView(viewModel: feedViewModel)
//                    .navigationTitle("News")
//            } label: {
//                Label {
//                    Text("News")
//                } icon: {
//                    Image(.news)
//                }
//            }

            SideMenuItem {
                SettingsView(api: api)
                    .navigationTitle("Settings")
            } label: {
                Label {
                    Text("Settings")
                } icon: {
                    Image(.settings)
                }
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
