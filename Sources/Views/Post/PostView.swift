import SwiftUI
import Prefire

struct PostView: View {
    var post: Post
    var alwaysShowFullText: Bool

    @Environment(\.instanceURL) private var instanceURL

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject private var palette: PaletteHolder

    private var horizontalPadding: CGFloat {
        horizontalSizeClass == .regular ? 13 : 4
    }

    @ScaledMetric(relativeTo: .body) private var repostVerticalLineThickness = 2
    @ScaledMetric(relativeTo: .body) private var repostContentPadding = 12

    private static let maxRepostChainDepth = 2

    @ViewBuilder
    private func singleRepost(_ repost: Repost, headerOnly: Bool) -> some View {
        VStack(alignment: .leading, spacing: horizontalSizeClass == .regular ? 13 : 6) {
            PostHeaderView(
                postHeader: repost.header,
                kind: .repost(isMastodonStyle: repost.isMastodonStyleRepost),
                horizontalSizeClass: horizontalSizeClass,
            )
            .padding(.horizontal, horizontalSizeClass == .regular ? 0 : 4)

            if !headerOnly {
                PostTextView(repost.text)
                    .padding(.horizontal, horizontalSizeClass == .regular ? 0 : 4)

                PostAttachmentsView(attachments: repost.attachments)
                    .padding(
                        .top,
                        repost.text.isEmpty
                            ? 0
                            : (horizontalSizeClass == .regular ? 10 : 6)
                    )
            }
        }
    }

    @ViewBuilder
    private func repostChain(
        _ reposts: ArraySlice<Repost>,
        hasContentAbove: Bool,
        depth: Int = 1,
    ) -> some View {
        if let repost = reposts.first {
            if horizontalSizeClass == .regular {
                HStack(spacing: 0) {
                    palette
                        .repostVerticalLine
                        .frame(width: repostVerticalLineThickness)
                    VStack(alignment: .leading, spacing: 0) {
                        singleRepost(
                            repost,
                            headerOnly: depth >= PostView.maxRepostChainDepth,
                        )
                        AnyView(
                            repostChain(
                                reposts.dropFirst(),
                                hasContentAbove: repost.hasContent,
                                depth: depth + 1,
                            )
                        )
                    }
                    .padding(.leading, 12)
                }
                .padding(.top, hasContentAbove ? 10 : 0)
            } else {
                // TODO: Remove Array() call in Swift 6.2
                ForEach(Array(reposts.enumerated()), id: \.element.id) { (i, repost) in
                    let hasTopPadding =
                        i == 0 && hasContentAbove || i > 0 && reposts[i - 1].hasContent
                    singleRepost(repost, headerOnly: i + 1 >= PostView.maxRepostChainDepth)
                        .padding(.top, hasTopPadding ? 6 : 0)
                }
            }
        } else {
            EmptyView()
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PostHeaderView(
                postHeader: post.header,
                kind: .regular,
                horizontalSizeClass: horizontalSizeClass,
            )
            .padding(.horizontal, horizontalPadding)
            .padding(.top, horizontalSizeClass == .regular ? 13 : 7)
            .padding(.bottom, 13)

            PostTextView(post.text)
                .padding(.horizontal, horizontalPadding)

            PostAttachmentsView(attachments: post.attachments)
                .padding(.horizontal, horizontalSizeClass == .regular ? 13 : 0)
                .padding(
                    .top,
                    post.text.isEmpty
                        ? 0
                        : (horizontalSizeClass == .regular ? 10 : 6)
                )

            repostChain(
                post.reposted.prefix(PostView.maxRepostChainDepth),
                hasContentAbove: post.hasContent
            )
            .padding(
                .horizontal,
                horizontalSizeClass == .regular ? 13 : 0
            )

            if horizontalSizeClass == .regular {
                palette.postFooterSeparator
                    .frame(width: .infinity, height: 1)
                    .padding(.leading, 16)
                    .padding(.top, 15)
            }

            PostFooterView(
                replyCount: post.replyCount,
                repostCount: post.repostCount,
                likesCount: post.likeCount,
                liked: post.liked,
            )
            .padding(.horizontal, horizontalPadding)
            .padding(.top, horizontalSizeClass == .regular ? 0 : 13)
            .padding(.bottom, horizontalSizeClass == .regular ? 0 : 11)
        }
        .background(Color.white)
        .colorScheme(.light)
        .draggableAsURL(post.originalPostURL(base: instanceURL))
    }
}

@available(iOS 17.0, *)
#Preview("Text-only post", traits: .sizeThatFitsLayout) {
    PostView(
        post: Post(
            id: PostID(rawValue: 1),
            remoteInstanceLink: URL(string: "https://example.com/posts/123")!,
            localAuthorID: URL(string: "/users/1")!,
            authorName: "Boromir",
            date: "five minutes ago",
            authorProfilePicture: .bundled(.boromirProfilePicture),
            text: "One does not simply walk into Mordor.",
            likeCount: 10,
            replyCount: 1,
            repostCount: 2,
            liked: false,
            reposted: []
        ),
        alwaysShowFullText: true,
    )
    .background { Color.white }
    .snapshot(precision: 0.98)
}

@available(iOS 17.0, *)
#Preview("Post with formatting", traits: .sizeThatFitsLayout) {
    PostView(
        post: Post(
            id: PostID(rawValue: 2),
            remoteInstanceLink: URL(string: "https://example.com/posts/123")!,
            localAuthorID: URL(string: "/users/1")!,
            authorName: "Boromir",
            date: "five minutes ago",
            authorProfilePicture: .bundled(.boromirProfilePicture),
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
            likeCount: 0,
            replyCount: 0,
            repostCount: 0,
            liked: false,
            reposted: [],
        ),
        alwaysShowFullText: true,
    )
    .background { Color.white }
    .snapshot(precision: 0.98)
}


@available(iOS 17.0, *)
#Preview("Truncated text-only post", traits: .sizeThatFitsLayout) {
    PostView(
        post: Post(
            id: PostID(rawValue: 3),
            remoteInstanceLink: URL(string: "https://example.com/posts/123")!,
            localAuthorID: URL(string: "/users/2")!,
            authorName: "Richard Stallman",
            date: "17 June 2009 at 13:12",
            authorProfilePicture: .bundled(.rmsProfilePicture),
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
            likeCount: 1311,
            replyCount: 129,
            repostCount: 34,
            liked: true,
        ),
        alwaysShowFullText: false,
    )
    .background { Color.white }
    .snapshot(precision: 0.98)
}

@available(iOS 17.0, *)
#Preview("Quote repost", traits: .sizeThatFitsLayout) {
    PostView(
        post: Post(
            id: PostID(rawValue: 4),
            remoteInstanceLink: URL(string: "https://example.com/posts/123")!,
            localAuthorID: URL(string: "/users/1")!,
            authorName: "Boromir",
            date: "five minues ago",
            authorProfilePicture: .bundled(.boromirProfilePicture),
            text: "Yes, I'm reposting my own post. And?",
            likeCount: 0,
            replyCount: 0,
            repostCount: 0,
            liked: false,
            reposted: [
                Repost(
                    id: PostID(rawValue: 4),
                    localAuthorID: URL(string: "/users/1")!,
                    authorName: "Boromir",
                    date: "seven minues ago",
                    authorProfilePicture: .bundled(.boromirProfilePicture),
                    text: "One does not simply walk into Mordor.",
                    isMastodonStyleRepost: false,
                )
            ]
        ),
        alwaysShowFullText: true,
    )
}

@available(iOS 17.0, *)
#Preview("Mastodon-style repost", traits: .sizeThatFitsLayout) {
    PostView(
        post: Post(
            id: PostID(rawValue: 4),
            remoteInstanceLink: URL(string: "https://example.com/posts/123")!,
            localAuthorID: URL(string: "/users/1")!,
            authorName: "Boromir",
            date: "five minues ago",
            authorProfilePicture: .bundled(.boromirProfilePicture),
            text: PostText(),
            likeCount: 0,
            replyCount: 122,
            repostCount: 13,
            liked: false,
            reposted: [
                Repost(
                    id: PostID(rawValue: 4),
                    localAuthorID: URL(string: "/users/1")!,
                    authorName: "Boromir",
                    date: "seven minues ago",
                    authorProfilePicture: .bundled(.boromirProfilePicture),
                    text: "One does not simply walk into Mordor.",
                    isMastodonStyleRepost: true,
                )
            ]
        ),
        alwaysShowFullText: true,
    )
}
