import Foundation
import Combine
import SwiftSoup

enum AuthenticationError: LocalizedError {
    case instanceNotFound(String)
    case notSmithereenInstance
    case invalidCredentials
    case other(any Error)

    var errorDescription: String? {
        // TODO: Actually localize
        switch self {
        case .instanceNotFound(let url):
            "Could not find a Smithereen instance at \(url)"
        case .notSmithereenInstance:
            "The provided instance is not a valid Smithereen server"
        case .invalidCredentials:
            "Invalid username or password"
        case .other(let error):
            error.localizedDescription
        }
    }
}

protocol AuthenticationService: Sendable {
    func authenticate(instance: URL, email: String, password: String) async throws(AuthenticationError)
    func logOut() async
}

protocol FeedService: Sendable {
    func loadFeed(start: Int?, offset: Int?) async throws -> [Post]
}

extension FeedService {
    func loadFeed() async throws -> [Post] {
        try await loadFeed(start: nil, offset: nil)
    }
}

struct MockApi: AuthenticationService, FeedService {
    func authenticate(instance: URL, email: String, password: String) async throws(AuthenticationError) {
    }

    func logOut() async {
    }

    func loadFeed(start: Int?, offset: Int?) async throws -> [Post] {
        return [
            Post(
                id: URL(string: "htts://smithereen.local/posts/1")!,
                localAuthorID: URL(string: "htts://smithereen.local/boromir")!,
                authorName: "Boromir",
                date: "five minutes ago",
                authorProfilePicture: .bundled(.boromirProfilePicture),
                text: try! PostText(html: "One does not simply walk into mordor."),
                likeCount: 1013,
                replyCount: 74,
                repostCount: 15,
                liked: true,
            ),
            Post(
                id: URL(string: "htts://smithereen.local/posts/2")!,
                localAuthorID: URL(string: "htts://smithereen.local/rms")!,
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
                replyCount: 34,
                repostCount: 129,
                liked: false,
            )
        ]
    }
}

struct ServerError: LocalizedError {
    var statusCode: Int
    var errorDescription: String {
        HTTPURLResponse.localizedString(forStatusCode: statusCode)
    }
}

private final class MyUrlSessionTaskDelegate: NSObject, URLSessionTaskDelegate {
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest
    ) async -> URLRequest? {
        return nil
    }
}

extension HTTPCookieStorage {
    private func getCookieByName(_ name: String) -> HTTPCookie? {
        guard let cookies = self.cookies else { return nil }
        for cookie in cookies {
            if cookie.isExpired {
                deleteCookie(cookie)
                continue
            }
            if cookie.name == name {
                return cookie
            }
        }
        return nil
    }

    fileprivate var psidCookie: HTTPCookie? {
        getCookieByName("psid")
    }

    fileprivate var jsessionCookie: HTTPCookie? {
        getCookieByName("JSESSIONID")
    }
}

private func alreadyAuthenticatedOnInstance() -> URL? {
    HTTPCookieStorage.shared.psidCookie.flatMap { URL(string: "https://" + $0.domain) }
}

@MainActor
final class AuthenticationState: ObservableObject {
    @Published var instance: URL? = alreadyAuthenticatedOnInstance()

    var isAuthenticated: Bool {
        instance != nil
    }

    @MainActor
    func setAuthenticated(instance: URL?) {
        self.instance = instance
    }
}

actor HTMLScrapingApi: AuthenticationService, FeedService {
    private let authenticationState: AuthenticationState
    private var csrf: String?

    init(authenticationState: AuthenticationState) {
        self.authenticationState = authenticationState
    }

    private let urlSession = URLSession(
        configuration: .default,
        delegate: MyUrlSessionTaskDelegate(),
        delegateQueue: nil
    )

    private func sendRequest(_ request: URLRequest) async throws -> (Document, Int) {
        let (data, response) = try await urlSession.data(for: request)
        let document = try SwiftSoup
            .parse(String(data: data, encoding: .utf8)!, request.url!.host!)
        return (document, (response as! HTTPURLResponse).statusCode)
    }

    private func createRequest(
        instance: URL,
        _ method: String,
        _ path: String,
        queryItems: [URLQueryItem]? = nil,
        cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
    ) -> URLRequest {
        var components = URLComponents(url: instance, resolvingAgainstBaseURL: false)!
        components.queryItems = queryItems
        components.path = path
        var request = URLRequest(url: components.url!, cachePolicy: cachePolicy)
        request.httpMethod = method
        request.setValue(
            "Mozilla/5.0 (iPhone; CPU OS 18_3_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.3 Mobile/14E304 Safari/605.1.15",
            forHTTPHeaderField: "User-Agent"
        )
        request.setValue(instance.host!, forHTTPHeaderField: "Host")
        request.setValue("text/html", forHTTPHeaderField: "Accept")
        request.setValue("en-GB,en", forHTTPHeaderField: "Accept-Language")
        return request
    }

    func authenticate(instance: URL, email: String, password: String) async throws(AuthenticationError) {
        // TODO: Check /activitypub/nodeinfo/2.1 and throw AuthenticationError.notSmithereenInstance if it's not Smithereen
        let escapedEmail = email.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let escapedPassword = password.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let body = "username=\(escapedEmail)&password=\(escapedPassword)"
        var request = createRequest(instance: instance, "POST", "/account/login")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = Data(body.utf8)
        let statusCode: Int
        do {
            (_, statusCode) = try await sendRequest(request)
        } catch {
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCannotFindHost {
                throw .instanceNotFound(instance.absoluteString)
            }
            throw .other(error)
        }
        if statusCode == 302 {
            await self.authenticationState.setAuthenticated(instance: instance)
        } else {
            throw .invalidCredentials
        }
    }

    func logOut() async {
        if let instance = await authenticationState.instance {
            let request = createRequest(
                instance: instance,
                "GET",
                "/account/logout",
                queryItems: [URLQueryItem(name: "csrf", value: csrf)],
            )
            Task {
                // Don't wait for the response.
                // If it fails, we don't care, we'll log out anyway.
                do {
                    _ = try await sendRequest(request)
                } catch {}
            }
        }
        if let psidCookie = HTTPCookieStorage.shared.psidCookie {
            HTTPCookieStorage.shared.deleteCookie(psidCookie)
        }
        if let jsessionCookie = HTTPCookieStorage.shared.jsessionCookie {
            HTTPCookieStorage.shared.deleteCookie(jsessionCookie)
        }
        await authenticationState.setAuthenticated(instance: nil)
    }

    private func saveCSRF(_ document: Document) {
        do {
            let logoutListItem = try document.select(".mainMenu .actionList > li").last()
            guard let logoutUrl = try logoutListItem?.select("a").attr("href"),
                  let components = URLComponents(string: logoutUrl) else {
                return
            }
            self.csrf = components.queryItems?.first { $0.name == "csrf" }?.value
        } catch {}
    }

    private func parsePicture(_ element: Element) -> URL? {
        do {
            for resource in try element.select("source") {
                if try resource.attr("type") != "image/webp" {
                    continue
                }
                let srcsets = try resource.attr("srcset")
                    .split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespaces) }

                for srcset in srcsets {
                    if srcset.hasSuffix(" 2x") {
                        return URL(string: String(srcset.prefix(srcset.count - 3)))
                    }
                }
            }
        } catch {
            // If there is an error, we ignonre it and return nil
        }
        return nil
    }

    private func parseSinglePost(
        _ container: Element,
        authorNameLinkSelector: String,
        postLinkSelector: String,
    ) throws -> PostHeader? {
        guard let authorNameLink = try container.select(authorNameLinkSelector).first(),
              let authorURL = try URL(string: authorNameLink.attr("href")) else {
            return nil
        }

        let authorName = try authorNameLink.text(trimAndNormaliseWhitespace: true)

        guard let postLink = try container.select(postLinkSelector).first(),
              let localPostURL = try URL(string: postLink.attr("href")) else {
            return nil
        }
        let date = try postLink.text(trimAndNormaliseWhitespace: true)

        let profilePicture = (try? container.select("span.avaHasImage picture").first())
            .flatMap(parsePicture)

//        let text = (try? postContent?.select(".expandableText .full").first()) ?? postContent

        return PostHeader(
            localInstanceLink: localPostURL,
            remoteInstanceLink: nil, // FIXME: the HTML from the mobile version that we use as data source doesn't contain the link to a remote server.
            localAuthorID: authorURL,
            authorName: authorName,
            date: date,
            authorProfilePicture: profilePicture.map(ImageLocation.remote),
        )
    }

    func loadFeed(start: Int?, offset: Int?) async throws -> [Post] {
        guard let instance = await self.authenticationState.instance else {
            throw AuthenticationError.invalidCredentials
        }
        let request = createRequest(instance: instance, "GET", "/feed")
        let (document, statusCode) = try await sendRequest(request)
        if statusCode != 200 {
            throw ServerError(statusCode: statusCode)
        }
        var posts: [Post] = []
        for postElement in try document.select(".post") {
            do {
                guard let postHeader = try parseSinglePost(
                    postElement,
                    authorNameLinkSelector: "a.authorName",
                    postLinkSelector: "a.postLink",
                ) else { continue }

                let postContent = try postElement.select(".postContent").first()
                let text = (try? postContent?.select(".expandableText .full").first()) ?? postContent

                func actionCount(_ actionName: String) throws -> Int {
                    try (
                        postElement
                            .select(".postActions .action.\(actionName) .counter")
                            .first()?
                            .text(trimAndNormaliseWhitespace: true)
                    ).flatMap(Int.init) ?? 0
                }

                let likeCount = try actionCount("like")
                let repostCount = try actionCount("share")
                let replyCount = try actionCount("comment")
                let liked = try !postElement.select(".postActions .action.like.liked").isEmpty()

                let reposts = try postElement
                    .select(".repostHeader")
                    .compactMap { repostHeaderElement -> Repost? in
                        guard let repostHeader = try parseSinglePost(
                            repostHeaderElement,
                            authorNameLinkSelector: "a.name",
                            postLinkSelector: "a.grayText"
                        ) else { return nil }

                        let postContent = try repostHeaderElement.nextElementSibling()
                        let text = (try? postContent?.select(".expandableText .full").first()) ?? postContent
                        let isMastodonStyle = try !repostHeaderElement
                            .select(".repostIcon.mastodonStyle").isEmpty()

                        return Repost(
                            header: repostHeader,
                            text: text.map(PostText.init) ?? PostText(),
                            isMastodonStyleRepost: isMastodonStyle,
                        )
                    }

                posts.append(
                    Post(
                        header: postHeader,
                        text: text.map(PostText.init) ?? PostText(),
                        likeCount: likeCount,
                        replyCount: replyCount,
                        repostCount: repostCount,
                        liked: liked,
                        reposted: reposts,
                    )
                )
            } catch {
                continue
            }
        }
        return posts
    }
}
