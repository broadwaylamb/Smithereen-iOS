import SmithereenAPI
import Combine
import Foundation
import Security
import AuthenticationServices

@MainActor
final class AuthViewModel: ObservableObject {
    let api: any AuthenticationService

    @Published var instanceAddress = ""

    init(api: any AuthenticationService) {
        self.api = api
    }

    private var hostAndPort: (String, Int?)? {
        if instanceAddress.isEmpty {
            return nil
        }
        var urlComponents: URLComponents
        if instanceAddress.starts(with: "http://")
            || instanceAddress.starts(with: "https://")
        {
            guard let c = URLComponents(string: instanceAddress) else {
                return nil
            }
            urlComponents = c
        } else if let components = URLComponents(string: instanceAddress),
            components.scheme != nil
        {
            return nil
        } else {
            guard let c = URLComponents(string: "https://" + instanceAddress) else {
                return nil
            }
            urlComponents = c
        }
        if urlComponents.host?.isEmpty ?? true {
            return nil
        }
        if let host = urlComponents.host {
            return (host, urlComponents.port)
        }

        return nil
    }

    var isValidInstanceAddress: Bool {
        hostAndPort != nil
    }

    nonisolated func logIn(session: SmithereenWebAuthenticationSession) async throws {
        guard let (host, port) = await hostAndPort else { return }

        let state = secureRandomBytes(count: 16)
            .base64EncodedURLString()

        let codeVerifier = secureRandomBytes(count: 32)
            .base64EncodedURLString()

        let url = OAuth.urlForAuthorizationCodeFlow(
            host: host,
            port: port,
            clientID: Constants.clientID,
            redirectURI: Constants.oauthRedirectURL,
            permissions: Permission.requiredPermissions,
            state: state,
            pkceCodeChallenge: codeVerifier.sha256(),
        )

        let callback: URL
        do {
            callback = try await session
                .authenticate(using: url, callbackURLScheme: Constants.appURLScheme)
        } catch let error as ASWebAuthenticationSessionError where error.code == .canceledLogin {
            // The user has dismissed the authentication web view.
            return
        }
        let authorizationCode: OAuth.AuthorizationCode
        do {
            authorizationCode = try OAuth
                .extractAuthorizationCode(from: callback, expectedState: state)
        } catch .rejected(let error) where error.code == .accessDenied {
            // The user has rejected authentication from the web interface.
            return
        } catch {
            // This seemingly redundant catch block prevents a Swift compiler crash.
            // Try to remove it and see if it's still needed.
            throw error
        }

        try await api.authenticate(
            host: host,
            port: port,
            method: OAuth.ExchangeAuthorizationCodeForAccessToken(
                code: authorizationCode,
                redirectUri: Constants.oauthRedirectURL,
                clientID: Constants.clientID,
                codeVerifier: codeVerifier,
            ),
        )
    }
}

