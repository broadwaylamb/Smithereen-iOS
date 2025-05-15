import SwiftUI

// https://www.fivestars.blog/articles/swiftui-share-layout-information/
struct SizeReaderViewModifier: ViewModifier {
    let onSizeChange: (CGSize) -> Void

    func body(content: Content) -> some View {
        content
            .background {
                GeometryReader { proxy in
                    Color.clear
                        .preference(key: SizePreferenceKey.self, value: proxy.size)
                        .onAppear {
                            onSizeChange(proxy.size)
                        }
                }
            }
            .onPreferenceChange(SizePreferenceKey.self, perform: onSizeChange)
    }
}

private struct SizePreferenceKey: PreferenceKey {
    typealias Value = CGSize

    static var defaultValue: CGSize { .zero }

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

extension View {
    func readSize(_ onChange: @escaping (CGSize) -> Void) -> ModifiedContent<Self, SizeReaderViewModifier> {
        modifier(SizeReaderViewModifier(onSizeChange: onChange))
    }
}
