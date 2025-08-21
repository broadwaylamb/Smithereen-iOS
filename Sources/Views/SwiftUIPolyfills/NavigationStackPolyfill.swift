import SwiftUI

private let useNativeNavigationStackWhenAvailable = true // For debugging purposes

/// Pre-iOS 16 polyfill for SwiftUI `NavigationStack`
struct NavigationStack<Root: View>: View {
    private var root: () -> Root
    @Binding private var path: NavigationPath

    @State private var destinationLookupTable = DestinationLookupTable()

    init(
        path: Binding<NavigationPath>,
        @ViewBuilder root: @escaping () -> Root,
    ) {
        self.root = root
        self._path = path
    }

    private var isActive: Binding<Bool> {
        Binding {
            !path.isEmpty
        } set: { isActive in
            if !path.isEmpty && !isActive {
                path = NavigationPath()
            }
        }
    }

    var body: some View {
        if #available(iOS 16.0, *), useNativeNavigationStackWhenAvailable {
            SwiftUI.NavigationStack(path: $path.native, root: root)
        } else {
            NavigationView {
                root()
                    .addInvisibleNavigationLink(
                        isActive: isActive,
                        path: $path,
                        pathIndex: 0,
                    )
                    .environment(\.viewFromData, destinationLookupTable.lookUp)
            }
            .navigationViewStyle(.stack)
            .onPreferenceChange(NavigationDestinationKey.self) {
                destinationLookupTable = $0
            }
        }
    }
}

private struct AddInvisibleNavigationLinkModifier: ViewModifier {
    var isActive: Binding<Bool>
    var path: Binding<NavigationPath>
    var pathIndex: Int

    @Environment(\.viewFromData) private var viewFromData

    func body(content: Content) -> some View {
        content
            .background {
                SwiftUI.NavigationLink(isActive: isActive) {
                    DestinationSelector(path: path, pathIndex: pathIndex)
                        .environment(\.viewFromData, viewFromData)
                } label: {
                    EmptyView()
                }
                .hidden()
            }
    }
}

extension View {
    fileprivate func addInvisibleNavigationLink(
        isActive: Binding<Bool>,
        path: Binding<NavigationPath>,
        pathIndex: Int,
    ) -> some View {
        modifier(
            AddInvisibleNavigationLinkModifier(
                isActive: isActive,
                path: path,
                pathIndex: pathIndex,
            )
        )
    }
}

private struct DestinationSelector: View {
    @Binding var path: NavigationPath
    var pathIndex: Int

    @Environment(\.viewFromData) private var viewFromData: (AnyHashable) -> AnyView

    private var isActive: Binding<Bool> {
        Binding {
            path.count > pathIndex + 1
        } set: { isActive in
            let count = path.count
            if count > pathIndex + 1 && !isActive {
                path.removeLast(count - pathIndex - 1)
                assert(path.count == pathIndex + 1)
            }
        }
    }

    var body: some View {
        if pathIndex < path.count {
            viewFromData(path.fallback[pathIndex])
                .addInvisibleNavigationLink(
                    isActive: isActive,
                    path: $path,
                    pathIndex: pathIndex + 1,
                )
        } else {
            EmptyView()
        }
    }
}

extension EnvironmentValues {
    @Entry var viewFromData: (AnyHashable) -> AnyView = {
        fatalError("Missing navigation destination for \($0)")
    }
}

private class NavigationPathBox {
    func append<V: Hashable>(_ value: V) {
        fatalError("abstract method")
    }

    func removeLast(_ k: Int) {
        fatalError("abstract method")
    }

    var isEmpty: Bool {
        fatalError("abstract method")
    }

    var count: Int {
        fatalError("abstract method")
    }

    func copy() -> NavigationPathBox {
        fatalError("abstract method")
    }
}

@available(iOS 16.0, *)
private final class NavigationPathBoxNative
    : NavigationPathBox,
      CustomDebugStringConvertible
{
    var path: SwiftUI.NavigationPath
    init(path: SwiftUI.NavigationPath) {
        self.path = path
    }

    override func append<V: Hashable>(_ value: V) {
        path.append(value)
    }

    override func removeLast(_ k: Int) {
        path.removeLast(k)
    }

    override var isEmpty: Bool {
        path.isEmpty
    }

    override var count: Int {
        path.count
    }

    override func copy() -> NavigationPathBox {
        NavigationPathBoxNative(path: path)
    }

    var debugDescription: String {
        String(reflecting: path)
    }
}

private final class NavigationPathBoxFallback
    : NavigationPathBox,
      CustomDebugStringConvertible
{
    var path: [AnyHashable]
    init(path: [AnyHashable]) {
        self.path = path
    }

    override func append<V: Hashable>(_ value: V) {
        path.append(AnyHashable(value))
    }

    override func removeLast(_ k: Int) {
        path.removeLast(k)
    }

    override var isEmpty: Bool {
        path.isEmpty
    }

    override var count: Int {
        path.count
    }

    override func copy() -> NavigationPathBox {
        NavigationPathBoxFallback(path: path)
    }

    var debugDescription: String {
        String(reflecting: path.map { $0.base })
    }
}

/// Pre-iOS 16 polyfill for SwiftUI `NavigationPath`
struct NavigationPath {
    fileprivate var box: NavigationPathBox

    @available(iOS 16.0, *)
    fileprivate var native: SwiftUI.NavigationPath {
        get {
            (box as! NavigationPathBoxNative).path
        }
        set {
            copyOnWrite()
            (box as! NavigationPathBoxNative).path = newValue
        }
    }

    fileprivate var fallback: [AnyHashable] {
        get {
            (box as! NavigationPathBoxFallback).path
        }
        set {
            copyOnWrite()
            (box as! NavigationPathBoxFallback).path = newValue
        }
    }

    init() {
        if #available(iOS 16.0, *), useNativeNavigationStackWhenAvailable {
            box = NavigationPathBoxNative(path: SwiftUI.NavigationPath())
        } else {
            box = NavigationPathBoxFallback(path: [])
        }
    }

    private mutating func copyOnWrite() {
        if !isKnownUniquelyReferenced(&box) {
            box = box.copy()
        }
    }

    mutating func append<V: Hashable>(_ value: V) {
        copyOnWrite()
        box.append(value)
    }

    mutating func removeLast(_ k: Int = 1) {
        copyOnWrite()
        box.removeLast(k)
    }

    var isEmpty: Bool {
        box.isEmpty
    }

    var count: Int {
        box.count
    }
}

extension NavigationPath: Equatable {
    static func == (lhs: NavigationPath, rhs: NavigationPath) -> Bool {
        if #available(iOS 16.0, *), useNativeNavigationStackWhenAvailable {
            return lhs.native == rhs.native
        } else {
            return lhs.fallback == rhs.fallback
        }
    }
}

private struct DestinationLookupTable: Equatable {
    var destinations: [(Any.Type, @MainActor (AnyHashable) -> AnyView)] = []

    @MainActor
    func lookUp(_ data: AnyHashable) -> AnyView {
        for (ty, destination) in destinations {
            if type(of: data.base) == ty {
                return destination(data)
            }
        }
        fatalError("Missing detination view for \(data.base)")
    }

    static func == (lhs: DestinationLookupTable, rhs: DestinationLookupTable) -> Bool {
        if lhs.destinations.count != rhs.destinations.count { return false }
        for (a, b) in zip(lhs.destinations, rhs.destinations) where a.0 != b.0 {
            return false
        }
        return true
    }
}

private struct NavigationDestinationKey: PreferenceKey {

    static let defaultValue = DestinationLookupTable()

    static func reduce(
        value: inout DestinationLookupTable,
        nextValue: () -> DestinationLookupTable,
    ) {
        value.destinations += nextValue().destinations
    }
}

private struct NavigationDestinationModifier<Data: Hashable, Destination: View>:
    ViewModifier
{
    var data: Data.Type
    var destination: @MainActor (Data) -> Destination

    func body(content: Content) -> some View {
        if #available(iOS 16.0, *), useNativeNavigationStackWhenAvailable {
            content
                .navigationDestination(for: data, destination: destination)
        } else {
            content.preference(
                key: NavigationDestinationKey.self,
                value: DestinationLookupTable(destinations: [
                    (
                        data,
                        { @MainActor anyHashable in
                            AnyView(destination(anyHashable as! Data))
                        }
                    )
                ])
            )
        }
    }
}

extension View {
    func navigationDestinationPolyfill<Data: Hashable, Content: View>(
        for data: Data.Type,
        @ViewBuilder destination: @escaping @MainActor (Data) -> Content
    ) -> some View {
        modifier(NavigationDestinationModifier(data: data, destination: destination))
    }
}

// Using SwiftUI's NavigationLink may cause the navigation path to fall out of sync.
// Make sure we don't accidentally use it.
@available(*, unavailable, message: "NavigationLink is not supported, use NavigationPath")
typealias NavigationLink = SwiftUI.NavigationLink
