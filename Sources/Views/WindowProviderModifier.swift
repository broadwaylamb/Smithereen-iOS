import SwiftUI
@_spi(Advanced) import SwiftUIIntrospect

struct WindowProvider {
    @Weak var _window: UIWindow?

    init() {
        _window = nil
    }

    init(window: Weak<UIWindow>) {
        __window = window
    }

    var window: UIWindow {
        if let _window {
            return _window
        }
        fatalError("""
            Missing window in window provider. \
            make sure you called `provideWindow()` at the root of the view hierarchy.
            """)
    }
}

private struct WindowProviderModifier: ViewModifier {
    @Weak var window: UIWindow?

    func body(content: Content) -> some View {
        content
            .introspect(.window, on: .iOS(.v15...)) { window in
                self.window = window
            }
            .environment(\.windowProvider, WindowProvider(window: _window))
    }
}

extension EnvironmentValues {
    @Entry var windowProvider: WindowProvider = WindowProvider()
}

extension View {
    func provideWindow() -> some View {
        modifier(WindowProviderModifier())
    }
}
