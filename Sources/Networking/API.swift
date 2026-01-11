import SwiftUI
import Foundation
import SmithereenAPI
import Hammond

enum AuthenticationError: LocalizedError {
    case instanceNotFound(String)
    case tokenError(OAuth.TokenError)
    case other(any Error)

    var errorDescription: String? {
        switch self {
        case .instanceNotFound(let url):
            return String(
                localized: "Could not find a Smithereen instance at \(url)",
                comment: "An error message on the login screen",
            )
        case .tokenError(let error):
            return error.errorDescription
        case .other(let error):
            return error.localizedDescription
        }
    }
}

protocol AuthenticationService: Sendable {
    func authenticate<Method: SmithereenOAuthTokenRequest>(
        host: String,
        port: Int?,
        method: Method,
    ) async throws

    func logOut() async
}

protocol APIService: AnyObject, Sendable {
    func invokeMethod<Method: SmithereenAPIRequest & Sendable>(
        _ method: Method
    ) async throws -> Method.Result
}

final class MockApi: AuthenticationService, APIService {
    func authenticate<Method: SmithereenOAuthTokenRequest>(
        host: String,
        port: Int?,
        method: Method,
    ) async throws {}

    func logOut() {}

    func invokeMethod<Method: SmithereenAPIRequest>(
        _ method: Method
    ) async throws -> Method.Result {
        fatalError("Not implemented yet")
    }
}

enum AuthenticationState {
    case loading
    case authenticated(ActorStorage)
    case notAuthenticated
}

actor RealAPIService: AuthenticationService, APIService, @MainActor ObservableObject {
    let keychain = KeychainAccess(service: Bundle.main.bundleIdentifier!)

    private var session: SessionInfo?

    @MainActor
    @Published var state: AuthenticationState = .loading

    @MainActor
    private func setUIState(_ state: AuthenticationState) {
        self.state = state
    }

    @MainActor
    private func setAuthenticated(_ session: SessionInfo) {
        state = .authenticated(ActorStorage(api: self, currentUserID: session.userID))
    }

    private func storeSession(_ session: SessionInfo?) async throws {
        try keychain.clear()
        self.session = nil
        if let session {
            try keychain.storeSession(session)
            self.session = session
            await setAuthenticated(session)
        } else {
            await setUIState(.notAuthenticated)
        }
    }

    func loadAuthenticationState() async {
        do {
            if let session = try keychain.retrieveSession() {
                self.session = session
                await setAuthenticated(session)
            } else {
                self.session = nil
                await setUIState(.notAuthenticated)
            }
        } catch {
            try? keychain.clear()
            self.session = nil
            await setUIState(.notAuthenticated)
        }
    }

    private struct Response: ResponseProtocol {
        var request: URLRequest
        var response: HTTPURLResponse
        var body: Data

        var statusCode: HTTPStatusCode {
            response.statusCode
        }
    }

    private func performRequest(
        _ urlRequest: URLRequest,
    ) async throws -> Response {
        var urlRequest = urlRequest
        urlRequest.addValue(Constants.userAgent, forHTTPHeaderField: "User-Agent")
        let (body, response) = try await URLSession.shared.data(for: urlRequest)
        return Response(
            request: urlRequest,
            response: response as! HTTPURLResponse,
            body: body,
        )
    }

    private func apiVersionOfHost(
        _ host: String,
        port: Int?,
    ) async throws -> SmithereenAPIVersion {
        let serverInfoRequest = Server.GetInfo()
        let data = try await performRequest(
            URLRequest(
                host: host,
                port: port,
                request: serverInfoRequest,
                globalParameters: GlobalRequestParameters(apiVersion: .v1_0),
            )
        )
        let info: Server.GetInfo.Result
        do {
            info = try serverInfoRequest.extractResult(from: data)
        } catch {
            throw AuthenticationError.instanceNotFound(host)
        }
        guard let version = info.apiVersions.smithereen else {
            throw AuthenticationError.instanceNotFound(host)
        }
        return version
    }

    func authenticate<Method: SmithereenOAuthTokenRequest>(
        host: String,
        port: Int?,
        method: Method,
    ) async throws {
        // We will use the value in later versions.
        // For now, make sure that the host exists and is actually a Smithereen instance.
        _ = try await apiVersionOfHost(host, port: port)

        let response = try await performRequest(
            URLRequest(
                host: host,
                port: port,
                request: method,
            )
        )
        let tokenResponse: OAuth.AccessTokenResponse
        do {
            tokenResponse = try method.extractResult(from: response)
        } catch let error as OAuth.TokenError {
            throw AuthenticationError.tokenError(error)
        } catch let error as DecodingError {
            throw ExtendedDecodingError(
                request: response.request,
                response: response.response,
                responseData: response.body,
                error: error,
            )
        }
        try await storeSession(
            SessionInfo(
                host: host,
                port: port,
                accessToken: tokenResponse.accessToken,
                userID: tokenResponse.userID,
            )
        )
    }

    private func invokeMethod<Method: SmithereenAPIRequest>(
        _ method: Method,
        session: SessionInfo,
    ) async throws -> Method.Result {
        let urlRequest = try URLRequest(
            host: session.host,
            port: session.port,
            request: method,
            globalParameters: GlobalRequestParameters(
                apiVersion: .v1_0,
                accessToken: session.accessToken,
                language: Locale.autoupdatingCurrent.identifier,
            ),
        )
        let response = try await performRequest(urlRequest)
        do {
            return try method.extractResult(from: response)
        } catch let error as DecodingError {
            throw ExtendedDecodingError(
                request: response.request,
                response: response.response,
                responseData: response.body,
                error: error,
            )
        }
    }

    func invokeMethod<Method: SmithereenAPIRequest>(
        _ method: Method
    ) async throws -> Method.Result {
        guard let session else {
            fatalError("Not authenticated")
        }
        return try await invokeMethod(method, session: session)
    }

    func logOut() async {
        guard let session else {
            return
        }
        try? await storeSession(nil)

        // Don't wait for the response.
        // If it fails, we don't care, we'll log out anyway.
        do {
            try await invokeMethod(Account.RevokeToken(), session: session)
        } catch {}
    }
}
