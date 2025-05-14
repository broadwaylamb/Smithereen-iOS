import SwiftUI
import Prefire

struct FeedView: View {
    @ObservedObject var viewModel: FeedViewModel
    @State private var error: AnyLocalizedError?

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
            PostView(
                profilePicture: .asyncImage(
                    AsyncImage(
                        url: post.authorProfilePictureURL,
                        scale: 2.0,
                        content: { $0.resizable() },
                        placeholder: { Color.gray },
                    )
                ),
                name: post.authorName,
                date: post.date,
                text: post.text,
                replyCount: post.replyCount,
                shareCount: post.repostCount,
                likesCount: post.likeCount,
            )
            .listSeparatorLeadingInset(-4)
            .listRowInsets(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4))
            .listRowSeparatorTint(Color(#colorLiteral(red: 0.7843137383, green: 0.7843137383, blue: 0.7843137383, alpha: 1)))
		}
		.listStyle(.plain)
		.toolbar {
			ToolbarItem(placement: .topBarTrailing) {
				Button(action: { /* TODO */ }) {
					Image(systemName: "square.and.pencil")
				}
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
        .background(Color.white)
        .colorScheme(.light)
    }
}

#Preview {
    FeedView(viewModel: FeedViewModel(api: MockApi()))
        .prefireIgnored()
}
