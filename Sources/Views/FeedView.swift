import Prefire
import SwiftUI

struct FeedView: View {
    @ObservedObject var viewModel: FeedViewModel

    @EnvironmentObject private var errorObserver: ErrorObserver

    @EnvironmentObject private var palette: PaletteHolder
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var composePostShown = false

    private func refreshFeed() async {
        await errorObserver.runCatching {
            try await viewModel.update()
        }
    }

    var body: some View {
        List(viewModel.posts) { postViewModel in
            Section {
                if horizontalSizeClass == .regular {
                    RegularPostView(viewModel: postViewModel)
                        .listSectionSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .shadow(
                            color: Color(#colorLiteral(red: 0.8445754647, green: 0.8591627479, blue: 0.8676676154, alpha: 1)),
                            radius: 0,
                            x: 0,
                            y: 1,
                        )
                        .listRowInsets(
                            EdgeInsets(top: 0, leading: 24, bottom: 0, trailing: 24)
                        )
                } else {
                    CompactPostView(viewModel: postViewModel)
                        .listRowInsets(
                            EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4)
                        )
                        .listSectionSeparatorTint(Color(#colorLiteral(red: 0.7843137383, green: 0.7843137383, blue: 0.7843137383, alpha: 1)))
                }
            } header: {
                // Removing the top blank space
                // https://stackoverflow.com/a/78618856
                Spacer(minLength: 0)
                    .listRowInsets(EdgeInsets())
            }
        }
        .listStyle(.grouped)
        .contentMarginsPolyfill(.top, horizontalSizeClass == .regular ? 16 : 0)
        .listSectionSpacingPolyfill(horizontalSizeClass == .regular ? 13 : 0)
        .environment(\.defaultMinListHeaderHeight, 0)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    composePostShown = true
                } label: {
                    Image(.composePost)
                }
                .disabled(!viewModel.canComposePost)
                .tint(Color.white)
            }
        }
        .sheet(isPresented: $composePostShown) {
            ComposePostView(
                "New Post",
                placeholder: "What's new?",
                viewModel: viewModel.createComposePostViewModel(
                    errorObserver: errorObserver,
                    isShown: $composePostShown,
                ),
            )
        }
        .task {
            await refreshFeed()
        }
        .refreshable {
            await refreshFeed()
        }
        .scrollContentBackgroundPolyfill(.hidden)
        .background(palette.feedBackground)
        .colorScheme(.light)
    }
}

#Preview {
    FeedView(viewModel: FeedViewModel(api: MockApi()))
        .prefireIgnored()
}
