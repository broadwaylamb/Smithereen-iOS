import SwiftUI
import Prefire

struct FeedView: View {
    let feedService: any FeedService
    @State private var posts: [Post] = []
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

    var body: some View {
        List(posts) { post in
            PostView(
                profilePicture: Image(.boromirProfilePicture),
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
        .onAppear {
            Task {
                do {
                    posts = try await feedService.loadFeed()
                } catch {
                    self.error = AnyLocalizedError(error: error)
                }
            }
        }
        .alert(isPresented: errorAlertShown, error: error) {
            Button("OK", action: {})
        }
        .colorScheme(.light)
    }
}

#Preview {
    FeedView(feedService: MockApi())
        .prefireIgnored()
}
