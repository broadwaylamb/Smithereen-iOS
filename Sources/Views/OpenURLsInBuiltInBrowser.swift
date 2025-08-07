import SwiftUI
@_spi(Advanced) import SwiftUIIntrospect
import SafariServices

// Yes, this is the best way to show SFSafariViewController in a SwiftUI app in 2025
// that doesn't break the multi-window scenario on iPad. I know.
private struct SafariViewModifier: ViewModifier {
    @Weak private var window: UIWindow?

    func body(content: Content) -> some View {
        content
            .introspect(.window, on: .iOS(.v15...)) { window in
                self.window = window
            }
            .environment(\.openURL, OpenURLAction { url in
                window?
                    .rootViewController?
                    .present(SFSafariViewController(url: url), animated: true)
                return .handled
            })
    }
}

extension View {
    func openURLsInBuiltInBrowser() -> some View {
        modifier(SafariViewModifier())
    }
}
