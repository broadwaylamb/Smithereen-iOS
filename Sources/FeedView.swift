import SwiftUI

struct FeedView: View {
    var body: some View {
		List {
			ForEach(0..<10, id: \.self) { _ in
				PostView(
					profilePicture: Image(.userProfilePicture),
					name: "Boromir",
					date: DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .none),
					text: "One does not simply walk into Mordor.",
					replyCount: 1,
					shareCount: 0,
					likesCount: 10,
				)
			}
		}
		.background(.white)
		.listStyle(.inset)
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
}
