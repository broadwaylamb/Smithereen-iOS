import SwiftUI
import AuthenticationServices

struct SmithereenWebAuthenticationSession {
    fileprivate let wrapper: Wrapper

    func authenticate(using url: URL, callbackURLScheme: String) async throws -> URL {
        try await wrapper.authenticate(
            using: url,
            callbackURLScheme: callbackURLScheme
        )
    }
}

private protocol Wrapper: Sendable {
    func authenticate(using url: URL, callbackURLScheme: String) async throws -> URL
}

@available(iOS 16.4, *)
private struct SwiftUIWebAuthenticationSessionWrapper: Wrapper {
    let session: WebAuthenticationSession
    init(session: WebAuthenticationSession) {
        self.session = session
    }

    func authenticate(using url: URL, callbackURLScheme: String) async throws -> URL {
        if #available(iOS 17.4, *) {
            return try await session.authenticate(
                using: url,
                callback: .customScheme(callbackURLScheme),
                preferredBrowserSession: .ephemeral,
                additionalHeaderFields: [:]
            )
        } else {
            return try await session.authenticate(
                using: url,
                callbackURLScheme: callbackURLScheme,
                preferredBrowserSession: .ephemeral,
            )
        }
    }
}

private final class UIKitWebAuthenticationSessionWrapper
    : NSObject,
      Wrapper,
      ASWebAuthenticationPresentationContextProviding
{
    let windowProvider: WindowProvider
    init(windowProvider: WindowProvider) {
        self.windowProvider = windowProvider
    }

    func authenticate(using url: URL, callbackURLScheme: String) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: callbackURLScheme,
            ) { callback, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                if let callback {
                    continuation.resume(returning: callback)
                }
            }
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = true
            session.start()
        }
    }

    func presentationAnchor(
        for session: ASWebAuthenticationSession
    ) -> ASPresentationAnchor {
        return windowProvider.window
    }
}

extension EnvironmentValues {
    @MainActor
    private struct Key: @MainActor EnvironmentKey {
        static var defaultValue: SmithereenWebAuthenticationSession {
            SmithereenWebAuthenticationSession(
                wrapper: UIKitWebAuthenticationSessionWrapper(windowProvider: .init())
            )
        }
    }

    @MainActor
    var smithereenWebAuthenticationSession: SmithereenWebAuthenticationSession {
        get {
            self[Key.self]
        }
        set {
            self[Key.self] = newValue
        }
    }
}

@available(iOS 16.4, *)
private struct SwiftUIModifier: ViewModifier {
    @Environment(\.webAuthenticationSession) var session

    func body(content: Content) -> some View {
        content.environment(
            \.smithereenWebAuthenticationSession,
             SmithereenWebAuthenticationSession(
                wrapper: SwiftUIWebAuthenticationSessionWrapper(session: session)
             ),
        )
    }
}

private struct UIKitModifier: ViewModifier {
    @Environment(\.windowProvider) var windowProvider

    func body(content: Content) -> some View {
        content.environment(
            \.smithereenWebAuthenticationSession,
            SmithereenWebAuthenticationSession(
                wrapper: UIKitWebAuthenticationSessionWrapper(
                    windowProvider: windowProvider
                )
            ),
        )
    }
}

extension View {
    func provideWebAuthenticationSession() -> some View {
        if #available(iOS 16.4, *) {
            return modifier(SwiftUIModifier())
        } else {
            return modifier(UIKitModifier())
        }
    }
}
