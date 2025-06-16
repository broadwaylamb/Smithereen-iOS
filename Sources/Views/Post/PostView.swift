import SwiftUI
import Prefire

struct PostView: View {
	var profilePicture: ImageLocation?
	var name: String
	var date: String
	var text: PostText
	var replyCount: Int
	var repostCount: Int
	var likesCount: Int
    var liked: Bool
    var originalPostURL: URL
    var alwaysShowFullText: Bool

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @AppStorage(.palette) private var palette: Palette = .smithereen

    private var horizontalPadding: CGFloat {
        horizontalSizeClass == .regular ? 13 : 4
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PostHeaderView(
                profilePicture: profilePicture,
                name: name,
                date: date,
            )
            .padding(.horizontal, horizontalPadding)
            .padding(.top, horizontalSizeClass == .regular ? 13 : 7)
            .padding(.bottom, 13)

            PostTextView(text)
                .padding(.horizontal, horizontalPadding)

            if horizontalSizeClass == .regular {
                palette.postFooterSeparator
                    .frame(width: .infinity, height: 1)
                    .padding(.leading, 16)
                    .padding(.top, 15)
            }

            PostFooterView(
                replyCount: replyCount,
                repostCount: repostCount,
                likesCount: likesCount,
                liked: liked,
            )
            .padding(.horizontal, horizontalPadding)
            .padding(.top, horizontalSizeClass == .regular ? 0 : 13)
            .padding(.bottom, horizontalSizeClass == .regular ? 0 : 11)
        }
        .background(Color.white)
        .colorScheme(.light)
        .draggableAsURL(originalPostURL)
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
        repostCount: 2,
        likesCount: 10,
        liked: false,
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
        text: try! PostText(html: """
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
        """),
        replyCount: 0,
        repostCount: 0,
        likesCount: 0,
        liked: false,
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
        text: try! PostText(html: """
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
        """),
        replyCount: 129,
        repostCount: 34,
        likesCount: 1311,
        liked: true,
        originalPostURL: URL(string: "https://example.com/posts/123")!,
        alwaysShowFullText: false,
    )
    .background { Color.white }
    .snapshot(precision: 0.98)
}
