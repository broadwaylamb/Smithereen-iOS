import UIKit

/// A strongly-typed version of `UIContentView` to avoid casts in implementations
protocol ContentView: UIContentView {
    associatedtype Configuration: UIContentConfiguration

    var configuration: Configuration { get set }
}

extension ContentView {
    @_implements(UIContentView, configuration)
    var __contentViewConfiguration: any UIContentConfiguration {
        get {
            configuration
        }
        set {
            configuration = newValue as! Configuration
        }
    }

    func supports(_ configuration: any UIContentConfiguration) -> Bool {
        configuration is Configuration
    }
}
