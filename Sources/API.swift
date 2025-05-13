import Foundation
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

@MainActor
protocol AuthenticationService: ObservableObject {
    var isAuthenticated: Bool { get }

    func authenticate(instance: URL, email: String, password: String) async throws(AuthenticationError)
}

@MainActor
protocol FeedService {
    func loadFeed(start: Int?, offset: Int?) async throws -> [Post]
}

extension FeedService {
    func loadFeed() async throws -> [Post] {
        try await loadFeed(start: nil, offset: nil)
    }
}

class MockApi: AuthenticationService, FeedService {
    @Published var isAuthenticated: Bool = false

    func authenticate(instance: URL, email: String, password: String) async throws(AuthenticationError) {
        isAuthenticated = true
    }

    func loadFeed(start: Int?, offset: Int?) async throws -> [Post] {
        return [
            Post(
                id: URL(string: "htts://smithereen.local")!,
                localAuthorID: URL(string: "htts://smithereen.local/boromir")!,
                authorName: "Boromir",
                date: "five minutes ago",
                text: "One does not simply walk into mordor.",
                likeCount: 1013,
                replyCount: 74,
                repostCount: 15,
            ),
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

class HTMLScrapingApi: AuthenticationService, FeedService {
    @Published var isAuthenticated: Bool
    private var instance: URL?

    init() {
        let cookie = (HTTPCookieStorage.shared.cookies ?? []).first {
            !$0.isExpired && $0.name == "psid"
        }
        if let cookie {
            instance = URL(string: "https://" + cookie.domain)
        }
        isAuthenticated = instance != nil
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
        cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
    ) -> URLRequest {
        var components = URLComponents(url: instance, resolvingAgainstBaseURL: false)!
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
            isAuthenticated = true
            self.instance = instance
        } else {
            throw .invalidCredentials
        }
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

    func loadFeed(start: Int?, offset: Int?) async throws -> [Post] {
        let request = createRequest(instance: instance!, "GET", "/feed")
        let (document, statusCode) = try await sendRequest(request)
        if statusCode != 200 {
            throw ServerError(statusCode: statusCode)
        }
        var posts: [Post] = []
        for post in try document.select(".post") {
            do {
                guard let authorNameLink = try post.select("a.authorName").first(),
                      let authorURL = try URL(string: authorNameLink.attr("href")) else {
                    continue
                }
                let authorName = try authorNameLink.text(trimAndNormaliseWhitespace: true)
                let text = try post.select(".postContent").first()
                guard let postLink = try post.select("a.postLink").first(),
                      let localPostURL = try URL(string: postLink.attr("href")) else {
                    continue
                }
                let remotePostURL =
                    try (postLink.nextSibling()?.nextSibling()?.attr("href"))
                        .flatMap(URL.init(string:))
                let date = try postLink.text(trimAndNormaliseWhitespace: true)

                let profilePicture = (try? post.select("span.avaHasImage picture").first())
                    .flatMap(parsePicture)

                func actionCount(_ actionName: String) throws -> Int {
                    try (
                        post
                            .select(".postActions .action.\(actionName) .counter")
                            .first()?
                            .text(trimAndNormaliseWhitespace: true)
                    ).flatMap(Int.init) ?? 0
                }

                let likeCount = try actionCount("like")
                let repostCount = try actionCount("share")
                let commentCount = try actionCount("comment")
                posts.append(
                    Post(
                        id: localPostURL,
                        remoteInstanceLink: remotePostURL,
                        localAuthorID: authorURL,
                        authorName: authorName,
                        date: date,
                        authorProfilePictureURL: profilePicture,
						text: text.map(renderHTML),
                        likeCount: likeCount,
                        replyCount: commentCount,
                        repostCount: repostCount,
                        reposted: nil, // TODO
                    )
                )
            } catch {
                continue
            }
        }
        return posts
    }
}
