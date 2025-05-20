import SwiftUI
import Prefire

struct PostView: View {
	var profilePicture: ImageLocation?
	var name: String
	var date: String
	var text: AttributedString?
	var replyCount: Int
	var shareCount: Int
	var likesCount: Int
    var originalPostURL: URL
    var alwaysShowFullText: Bool

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var padding: EdgeInsets {
        switch horizontalSizeClass {
        case .regular:
            EdgeInsets(top: 13, leading: 13, bottom: 13, trailing: 13)
        default:
            EdgeInsets(top: 7, leading: 4, bottom: 11, trailing: 4)
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            PostHeaderView(
                profilePicture: profilePicture,
                name: name,
                date: date,
            )
            if let text {
                ExpandableText(text, lineLimit: alwaysShowFullText ? nil : 12)
            }
            PostFooterView(
                replyCount: replyCount,
                shareCount: shareCount,
                likesCount: likesCount,
            )
        }
        .padding(padding)
        .background(Color.white)
        .colorScheme(.light)
        .draggableAsURL(originalPostURL)
    }
}

private struct PostHeaderView: View {
	var profilePicture: ImageLocation?
	var name: String
	var date: String

    @Environment(\.palette) private var palette

    @ScaledMetric(relativeTo: .body)
    private var imageSize = 44

    @ViewBuilder
    private var profilePictureImage: some View {
        switch profilePicture {
        case .remote(let url):
            AsyncImage(
                url: url,
                scale: 2.0,
                content: { $0.resizable() },
                placeholder: { Color.gray },
            )
        case .bundled(let resource):
            Image(resource)
                .resizable()
        case nil:
            Color.red // TODO
        }
    }

	var body: some View {
		HStack(spacing: 8) {
			profilePictureImage
				.frame(width: imageSize, height: imageSize)
				.cornerRadius(5)
			VStack(alignment: .leading, spacing: 7) {
				Text(name)
					.bold()
                    .foregroundStyle(palette.accent)
				Text(date)
					.font(.caption)
					.foregroundStyle(.secondary)
			}
			Spacer()
			Button(action: { /* TODO */ }) {
                Image(systemName: "ellipsis").foregroundStyle(palette.ellipsis)
			}
		}
	}
}

private let numberFormatter: NumberFormatter = {
	let formatter = NumberFormatter()
	formatter.numberStyle = .decimal
	return formatter
}()

private struct PostFooterView: View {
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
        profilePicture: .bundled(.boromirProfilePicture),
        name: "Boromir",
        date: "five minutes ago",
        text: "One does not simply walk into Mordor.",
        replyCount: 1,
        shareCount: 0,
        likesCount: 10,
        originalPostURL: URL(string: "https://example.com/posts/123")!,
        alwaysShowFullText: true,
    )
    .background { Color.white }
    .snapshot(precision: 0.98)
}

@available(iOS 17.0, *)
#Preview("Post with formatting", traits: .sizeThatFitsLayout) {
    PostView(
        profilePicture: .bundled(.boromirProfilePicture),
        name: "Boromir",
        date: "five minutes ago",
        text: """
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
        """.renderAsHTML(),
        replyCount: 0,
        shareCount: 0,
        likesCount: 0,
        originalPostURL: URL(string: "https://example.com/posts/123")!,
        alwaysShowFullText: true,
    )
    .background { Color.white }
    .snapshot(precision: 0.98)
}


@available(iOS 17.0, *)
#Preview("Truncated text-only post", traits: .sizeThatFitsLayout) {
    PostView(
        profilePicture: .bundled(.rmsProfilePicture),
        name: "Richard Stallman",
        date: "17 June 2009 at 13:12",
        text: """
        <p>
        I'd just like to interject for a moment.  What you're referring to as Linux,
        is in fact, GNU/Linux, or as I've recently taken to calling it, GNU plus Linux.
        Linux is not an operating system unto itself, but rather another free component
        of a fully functioning GNU system made useful by the GNU corelibs, shell
        utilities and vital system components comprising a full OS as defined by POSIX.
        </p>
        <p>
        Many computer users run a modified version of the GNU system every day,
        without realizing it.  Through a peculiar turn of events, the version of GNU
        which is widely used today is often called "Linux", and many of its users are
        not aware that it is basically the GNU system, developed by the GNU Project.
        </p>
        <p>
        There really is a Linux, and these people are using it, but it is just a
        part of the system they use.  Linux is the kernel: the program in the system
        that allocates the machine's resources to the other programs that you run.
        The kernel is an essential part of an operating system, but useless by itself;
        it can only function in the context of a complete operating system.  Linux is
        normally used in combination with the GNU operating system: the whole system
        is basically GNU with Linux added, or GNU/Linux.  All the so-called "Linux"
        distributions are really distributions of GNU/Linux.
        </p>
        """.renderAsHTML(),
        replyCount: 129,
        shareCount: 34,
        likesCount: 1311,
        originalPostURL: URL(string: "https://example.com/posts/123")!,
        alwaysShowFullText: false,
    )
    .background { Color.white }
    .snapshot(precision: 0.98)
}
