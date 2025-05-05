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

class DummyAuthenticationService: AuthenticationService {
    @Published var isAuthenticated: Bool = false

    func authenticate(instance: URL, email: String, password: String) async throws(AuthenticationError) {
        isAuthenticated = true
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

class HTMLScrapingAuthenticationService: AuthenticationService {
    @Published var isAuthenticated: Bool = false

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
        request.setValue("Smithereen-iOS/0.1", forHTTPHeaderField: "User-Agent")
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
        } else {
            throw .invalidCredentials
        }
    }
}
