import SwiftUI
import Prefire

struct FeedView: View {
    @ObservedObject var viewModel: FeedViewModel
    @State private var error: AnyLocalizedError?

    @AppStorage(.palette) private var palette: Palette = .smithereen
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var errorAlertShown: Binding<Bool> {
        Binding {
            error != nil
        } set: {
            if !$0 {
                error = nil
            }
        }

    }

    private func refreshFeed() async {
        do {
            try await viewModel.update()
        } catch {
            self.error = AnyLocalizedError(error: error)
        }
    }

    var body: some View {
        List(viewModel.posts) { post in
            Section {
                let postView = PostView(
                    profilePicture: post.authorProfilePicture,
                    name: post.authorName,
                    date: post.date,
                    text: post.text,
                    replyCount: post.replyCount,
                    repostCount: post.repostCount,
                    likesCount: post.likeCount,
                    liked: post.liked,
                    originalPostURL: post.remoteInstanceLink ?? post.id,
                    alwaysShowFullText: false,
                )
                if horizontalSizeClass == .regular {
                    postView
                        .listSectionSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .shadow(color: Color(#colorLiteral(red: 0.8445754647, green: 0.8591627479, blue: 0.8676676154, alpha: 1)), radius: 0, x: 0, y: 1)
                        .listRowInsets(
                            EdgeInsets(top: 0, leading: 24, bottom: 0, trailing: 24)
                        )
                } else {
                    postView
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
				Button(action: { /* TODO */ }) {
					Image(systemName: "square.and.pencil")
				}
                .tint(Color.white)
            }
		}
        .task {
            await refreshFeed()
        }
        .refreshable {
            await refreshFeed()
        }
        .alert(isPresented: errorAlertShown, error: error) {
            Button("OK", action: {})
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
