import Combine
import Foundation
import Hammond
import HammondEncoders
import SwiftSoup
import SmithereenAPI

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
    func invokeMethod<Method: SmithereenAPIRequest & Sendable>(
        _ method: Method
    ) async throws -> Method.Result
}

struct MockApi: AuthenticationService, APIService {
    func authenticate(instance: URL, email: String, password: String) async throws {
    }

    func logOut() {
    }

    func invokeMethod<Method: SmithereenAPIRequest>(
        _ method: Method
    ) async throws -> Method.Result {
        fatalError("Not implemented yet")
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

actor RealAPIService: APIService {
    func invokeMethod<Method: SmithereenAPIRequest>(
        _ method: Method
    ) async throws -> Method.Result {
        fatalError("Not implemented yet")
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

            return try request
                .extractResult(
                    from: ResponseAdapter(
                        statusCode: urlResponse.statusCode,
                        body: document as! Request.ResponseBody,
                    )
                )
        } else if Request.ResponseBody.self == Data.self {
            return try request.extractResult(
                from: ResponseAdapter(
                    statusCode: urlResponse.statusCode,
                    body: data as! Request.ResponseBody
                )
            )
        } else {
            fatalError("Unsupported request body type")
        }
    }

    func invokeMethod<Method: SmithereenAPIRequest>(
        _ method: Method,
    ) async throws -> Method.Result {
        fatalError("Not supported")
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
