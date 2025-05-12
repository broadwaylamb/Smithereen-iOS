import SwiftUI
import Prefire

struct PostView: View {
	var profilePicture: Image
	var name: String
	var date: String
	var text: AttributedString?
	var replyCount: Int
	var shareCount: Int
	var likesCount: Int

    var body: some View {
        VStack(alignment: .leading) {
            PostHeaderView(profilePicture: profilePicture, name: name, date: date)
            if let text {
				Text(text)
            }
            PostFooterView(replyCount: replyCount, shareCount: shareCount, likesCount: likesCount)
        }
        .padding(EdgeInsets(top: 7, leading: 4, bottom: 11, trailing: 4))
        .colorScheme(.light)
    }
}

struct PostHeaderView: View {
	var profilePicture: Image
	var name: String
	var date: String

    @ScaledMetric(relativeTo: .body)
    private var imageSize = 44

	var body: some View {
		HStack(spacing: 8) {
			profilePicture
				.resizable()
				.frame(width: imageSize, height: imageSize)
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
                Image(systemName: "ellipsis").foregroundStyle(Color(#colorLiteral(red: 0.8549019098, green: 0.8549019694, blue: 0.8549019694, alpha: 1)))
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

    @Environment(\.layoutDirection)
    private var layoutDirection: LayoutDirection

	private func formatCount(_ count: Int) -> String? {
		count == 0 ? nil : numberFormatter.string(from: count as NSNumber)
	}

	var body: some View {
		HStack {
            PostFooterButton(image: Icons.comment(layoutDirection), text: formatCount(replyCount))
			Spacer()
            PostFooterButton(image: Icons.share(), text: formatCount(shareCount))
            PostFooterButton(image: Icons.like(), text: formatCount(likesCount))
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

@available(iOS 17.0, *)
#Preview("Text-only post", traits: .sizeThatFitsLayout) {
    PostView(
        profilePicture: Image(.boromirProfilePicture),
        name: "Boromir",
        date: "five minutes ago",
        text: "One does not simply walk into Mordor.",
        replyCount: 1,
        shareCount: 0,
        likesCount: 10,
    )
    .background { Color.white }
    .snapshot(precision: 0.98)
}

@available(iOS 17.0, *)
#Preview("Post with formatting", traits: .sizeThatFitsLayout) {
    PostView(
        profilePicture: Image(.boromirProfilePicture),
        name: "Boromir",
        date: "five minutes ago",
        text: renderHTML(
            """
            <p>
             First
            paragraph
            </p>
            <p>
            Multiple
            <br/>
             lines
            <br/>
            in one pararaph
            </p>
            <p>
             <b> Bold</b>, <i> italic</i>, <b><i>bold and italic</i></b>,
            <u>underline</u>,
            <s>strikethrough</s>, 
            <code>inline code</code>, <a href="http://example.com">link</a>.
            </p>
            <pre>
            Code block
            <pre>    nested code block</pre>
            <b>bold</b> — &lt;b&gt;not bold!&lt;/b&gt;
                         S
                         A
                        LUT
                         M
                        O N
                        D  E
                        DONT
                       E SUIS
                       LA LAN
                      G U E  É
                     L O Q U E N
                    TE      QUESA
                   B  O  U  C  H  E
                  O        P A R I S
                 T I R E   ET   TIRERA
                T O U             JOURS
               AUX                  A  L
             LEM                      ANDS
            </pre>
            <blockquote>
            Quote
            </blockquote>
            """
        ),
        replyCount: 0,
        shareCount: 0,
        likesCount: 0,
    )
    .background { Color.white }
    .snapshot(precision: 0.98)
}

