import SwiftUI
import Prefire

struct FeedView: View {
    var body: some View {
		List {
			ForEach(0..<10, id: \.self) { _ in
				PostView(
                    profilePicture: Image(.boromirProfilePicture),
					name: "Boromir",
					date: "five minutes ago",
					text: "One does not simply walk into Mordor.",
					replyCount: 1,
					shareCount: 0,
					likesCount: 10,
				)
                .listSeparatorLeadingInset(-4)
                .listRowInsets(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4))
                .listRowSeparatorTint(Color(#colorLiteral(red: 0.7843137383, green: 0.7843137383, blue: 0.7843137383, alpha: 1)))
			}
		}
		.listStyle(.plain)
		.toolbar {
			ToolbarItem(placement: .topBarTrailing) {
				Button(action: { /* TODO */ }) {
					Image(systemName: "square.and.pencil")
				}
			}
		}
    }
}

#Preview {
    FeedView()
        .prefireIgnored()
}
