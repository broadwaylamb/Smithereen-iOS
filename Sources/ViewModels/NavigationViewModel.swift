import SwiftUI

final class NavigationViewModel: ObservableObject {
    @Published var navigationPath = NavigationPath()

}

extension EnvironmentValues {
    @Entry var pushToNavigationStack: (any Hashable) -> Void = { _ in }
}
