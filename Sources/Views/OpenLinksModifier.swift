import SwiftUI
@_spi(Advanced) import SwiftUIIntrospect
import SafariServices

// Yes, this is the best way to show SFSafariViewController in a SwiftUI app in 2025
// that doesn't break the multi-window scenario on iPad. I know.
private struct OpenLinkModifier: ViewModifier {
    @Weak private var window: UIWindow?

    @Environment(\.pushToNavigationStack) private var pushToNavigationStack

    func body(content: Content) -> some View {
        content
            .introspect(.window, on: .iOS(.v15...)) { window in
                self.window = window
            }
            .environment(\.openURL, OpenURLAction { url in
                if url.scheme == "http" || url.scheme == "https" {
                    window?
                        .rootViewController?
                        .present(SFSafariViewController(url: url), animated: true)
                    return .handled
                }
                if url.host == nil && url.path.starts(with: "/") {
                    // Local URL, must be a user
                    let userHandle = url.path.dropFirst()
                    let userHandleWithoutDomain =
                        userHandle.split(separator: "@").first ?? userHandle
                    pushToNavigationStack(
                        UserProfileNavigationItem(
                            firstName: String(userHandleWithoutDomain),
                            userHandle: String(userHandle),
                        )
                    )
                    return .handled
                }
                return .systemAction
            })
    }
}

extension View {
    func openLinks() -> some View {
        modifier(OpenLinkModifier())
    }
}
