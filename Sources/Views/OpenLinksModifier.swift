import SwiftUI
import SafariServices

// Yes, this is the best way to show SFSafariViewController in a SwiftUI app in 2025
// that doesn't break the multi-window scenario on iPad. I know.
private struct OpenLinkModifier: ViewModifier {
    @Environment(\.windowProvider) var windowProvider

    func body(content: Content) -> some View {
        content
            .environment(\.openURL, OpenURLAction { url in
                if url.scheme == "http" || url.scheme == "https" {
                    windowProvider.window
                        .rootViewController?
                        .present(SFSafariViewController(url: url), animated: true)
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
