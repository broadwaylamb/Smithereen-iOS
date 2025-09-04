import Combine
import Foundation
import Hammond
import SwiftSoup

enum AuthenticationError: LocalizedError {
    case instanceNotFound(String)
    case invalidCredentials
    case other(any Error)

    var errorDescription: String? {
        switch self {
        case .instanceNotFound(let url):
            String(
                localized: "Could not find a Smithereen instance at \(url)",
                comment: "An error message on the login screen",
            )
        case .invalidCredentials:
            String(
                localized: "Wrong email/username or password",
                comment: "An error message on the login screen",
            )
        case .other(let error):
            error.localizedDescription
        }
    }
}

protocol AuthenticationService: Sendable {
    func authenticate(instance: URL, email: String, password: String) async throws

    @MainActor
    func logOut()
}

protocol APIService: Sendable {
    func send<Request: DecodableRequestProtocol>(
        _ request: Request,
        instance: URL?,
    ) async throws -> Request.Result
}

extension APIService {
    func send<Request: DecodableRequestProtocol>(
        _ request: Request,
    ) async throws -> Request.Result {
        try await send(request, instance: nil)
    }
}

struct MockApi: AuthenticationService, APIService {
    func authenticate(instance: URL, email: String, password: String) async throws {
    }

    func logOut() {
    }

    func send<Request: DecodableRequestProtocol>(
        _ request: Request,
        instance: URL?
    ) async throws -> Request.Result {
        if request is FeedRequest {
            return FeedResponse(
                posts: [
                    Post(
                        id: PostID(rawValue: 1),
                        localURL: URL(string: "https://smithereen.local/posts/1")!,
                        authorHandle: "boromir",
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
                        id: PostID(rawValue: 2),
                        localURL: URL(string: "https://smithereen.local/posts/2")!,
                        authorHandle: "rms",
                        authorName: "Richard Stallman",
                        date: "17 June 2009 at 13:12",
                        authorProfilePicture: .bundled(.rmsProfilePicture),
                        text: try! PostText(
                            html: """
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
                            """
                        ),
                        likeCount: 1311,
                        replyCount: 34,
                        repostCount: 129,
                        liked: false,
                    ),
                ],
                currentUserID: UserID(rawValue: 1),
            ) as! Request.Result
        }
        if request is UserProfileRequest {
            return UserProfile(
                fullName: "Boromir",
                profilePicture: .bundled(.boromirProfilePicture),
                presence: "online",
                friendCount: 42,
                commonFriendCount: 12,
                followerCount: 100,
                groupCount: 2,
            ) as! Request.Result
        }

        fatalError("No mock data for this request")
    }
}

private final class MyUrlSessionTaskDelegate: NSObject, URLSessionTaskDelegate {
    let ignoresRedirects: Bool
    init(ignoresRedirects: Bool) {
        self.ignoresRedirects = ignoresRedirects
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest
    ) async -> URLRequest? {
        if ignoresRedirects {
            return nil
        }
        guard let redirectURL = request.url else { return request }
        var urlComponents =
            URLComponents(url: redirectURL, resolvingAgainstBaseURL: false)!
        if urlComponents.scheme == "http" {
            urlComponents.scheme = "https"
        }
        var request = request
        request.url = urlComponents.url!
        return request
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
    @Published var authenticatedInstance: URL? = alreadyAuthenticatedOnInstance()

    @MainActor
    func setAuthenticated(instance: URL?) {
        self.authenticatedInstance = instance
    }
}

actor HTMLScrapingApi: AuthenticationService, APIService {
    private let authenticationState: AuthenticationState
    private var csrf: URLQueryItem?

    init(authenticationState: AuthenticationState) {
        self.authenticationState = authenticationState
    }

    private let ignoringRedirectsUrlSession = URLSession(
        configuration: .default,
        delegate: MyUrlSessionTaskDelegate(ignoresRedirects: true),
        delegateQueue: nil,
    )

    private let respectingRedirectsURLSession = URLSession(
        configuration: .default,
        delegate: MyUrlSessionTaskDelegate(ignoresRedirects: false),
        delegateQueue: nil,
    )

    func send<Request: DecodableRequestProtocol>(
        _ request: Request,
        instance: URL? = nil,
    ) async throws -> Request.Result {
        var instance = instance
        if instance == nil {
            instance = await self.authenticationState.authenticatedInstance
        }
        guard let instance else {
            throw AuthenticationError.invalidCredentials
        }

        let encodableQuery = (request as? (any EncodableRequestProtocol))?.encodableQuery
        let encodableBody = (request as? (any EncodableRequestProtocol))?.encodableBody

        let encoder = URLEncodedFormEncoder()
        var queryItems = [URLQueryItem]()
        if let encodableQuery {
            try encoder.encode(encodableQuery, into: &queryItems)
        }
        if request is RequiresCSRF, let csrf {
            queryItems.append(csrf)
        }

        var components = URLComponents(url: instance, resolvingAgainstBaseURL: false)!
        components.queryItems = queryItems
        components.path = request.path

        var urlRequest = URLRequest(url: components.url!)
        urlRequest.httpMethod = Request.method.rawValue

        // Mimic to a mobile web browser so that the server sends us the mobile
        // version.
        urlRequest.setValue(
            """
            Mozilla/5.0 (iPhone; CPU OS 18_3_1 like Mac OS X) AppleWebKit/605.1.15 \
            (KHTML, like Gecko) Version/18.3 Mobile/14E304 Safari/605.1.15
            """,
            forHTTPHeaderField: "User-Agent"
        )

        urlRequest.setValue(instance.host!, forHTTPHeaderField: "Host")
        urlRequest.setAccept(Request.accept)

        switch Request.method {
        case .post:
            if let encodableBody {
                urlRequest.setContentType(Request.contentType)
                if Request.contentType == .application.formURLEncoded {
                    urlRequest.httpBody = Data(try encoder.encode(encodableBody).utf8)
                }
            }
        default:
            break
        }

        let session = request is IgnoreRedirects
            ? ignoringRedirectsUrlSession
            : respectingRedirectsURLSession
        let (data, urlResponse) = try await session.data(for: urlRequest)

        if Request.ResponseBody.self == SwiftSoup.Document.self {
            let document = try SwiftSoup
                .parse(String(decoding: data, as: UTF8.self), urlRequest.url!.host!)

            saveCSRF(document)

            return try Request
                .extractResult(
                    from: ResponseAdapter(
                        statusCode: urlResponse.statusCode,
                        body: document as! Request.ResponseBody,
                    )
                )
        } else if Request.ResponseBody.self == Data.self {
            return try Request.extractResult(
                from: ResponseAdapter(
                    statusCode: urlResponse.statusCode,
                    body: data as! Request.ResponseBody
                )
            )
        } else {
            fatalError("Unsupported request body type")
        }
    }

    private struct ResponseAdapter<Body>: ResponseProtocol {
        var statusCode: HTTPStatusCode
        var body: Body
    }

    private func saveCSRF(_ document: Document) {
        do {
            let logoutListItem = try document.select(".mainMenu .actionList > li").last()
            guard let logoutUrl = try logoutListItem?.select("a").attr("href"),
                  let components = URLComponents(string: logoutUrl)
            else {
                return
            }
            self.csrf = components.queryItems?.first { $0.name == "csrf" }
        } catch {}
    }

    func authenticate(instance: URL, email: String, password: String) async throws {
        do {
            try await send(
                LogInRequest(username: email, password: password),
                instance: instance,
            )
        } catch let error as AuthenticationError {
            throw error
        } catch {
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain
                && nsError.code == NSURLErrorCannotFindHost
            {
                throw AuthenticationError.instanceNotFound(instance.absoluteString)
            }
            throw AuthenticationError.other(error)
        }
        await self.authenticationState.setAuthenticated(instance: instance)
    }

    @MainActor
    func logOut() {
        Task {
            // Don't wait for the response.
            // If it fails, we don't care, we'll log out anyway.
            do {
                try await send(LogOutRequest())
            } catch {}
        }
        if let psidCookie = HTTPCookieStorage.shared.psidCookie {
            HTTPCookieStorage.shared.deleteCookie(psidCookie)
        }
        if let jsessionCookie = HTTPCookieStorage.shared.jsessionCookie {
            HTTPCookieStorage.shared.deleteCookie(jsessionCookie)
        }
        authenticationState.setAuthenticated(instance: nil)
    }
}
