import SwiftUI

struct PostView: View {
	var profilePicture: Image
	var name: String
	var date: String
	var text: String
	var replyCount: Int
	var shareCount: Int
	var likesCount: Int

    var body: some View {
		VStack(alignment: .leading) {
			PostHeaderView(profilePicture: profilePicture, name: name, date: date)
			Text(verbatim: text)
			PostFooterView(replyCount: replyCount, shareCount: shareCount, likesCount: likesCount)
		}
		.padding(4)
    }
}

struct PostHeaderView: View {
	var profilePicture: Image
	var name: String
	var date: String

	var body: some View {
		HStack(spacing: 8) {
			profilePicture
				.resizable()
				.frame(width: 44, height: 44)
				.cornerRadius(5)
			VStack(alignment: .leading, spacing: 7) {
				Text(name)
					.bold()
					.foregroundStyle(Color.accentColor)
				Text(date)
					.font(.caption)
					.foregroundStyle(.secondary)
			}
			Spacer()
			Button(action: { /* TODO */ }) {
				Image(systemName: "ellipsis")
					.tint(.secondary)
			}
		}
	}
}

private let numberFormatter: NumberFormatter = {
	let formatter = NumberFormatter()
	formatter.numberStyle = .decimal
	return formatter
}()

struct PostFooterView: View {
	var replyCount: Int
	var shareCount: Int
	var likesCount: Int

	private func formatCount(_ count: Int) -> String? {
		count == 0 ? nil : numberFormatter.string(from: count as NSNumber)
	}

	var body: some View {
		HStack {
			PostFooterButton(image: Image(systemName: "bubble.fill"), text: formatCount(replyCount))
			Spacer()
			PostFooterButton(image: Image(systemName: "megaphone.fill"), text: formatCount(shareCount))
			PostFooterButton(image: Image(systemName: "heart.fill"), text: formatCount(likesCount))
		}
	}
}

struct PostFooterButton: View {
	var image: Image
	var text: String?
	var body: some View {
		Button(action: { /* TODO */ }) {
			HStack(spacing: 8) {
				image
				if let text {
					Text(verbatim: text)
				}
			}
		}
		.padding(7)
		.foregroundStyle(Color(#colorLiteral(red: 0.6374332905, green: 0.6473867297, blue: 0.6686993241, alpha: 1)))
		.background(Color(#colorLiteral(red: 0.9188938141, green: 0.93382442, blue: 0.9421684742, alpha: 1)))
		.cornerRadius(4)
	}
}

#Preview {
	PostView(
		profilePicture: Image(.userProfilePicture),
		name: "Boromir",
		date: DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .none),
		text: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.",
		replyCount: 1,
		shareCount: 0,
		likesCount: 10,
	)
}
