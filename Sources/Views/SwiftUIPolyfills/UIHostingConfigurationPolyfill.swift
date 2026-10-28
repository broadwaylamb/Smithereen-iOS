import SwiftUI
import UIKit

// https://gist.github.com/simonbs/457725e218fc85fc765ed770815314df

struct UIHostingConfigurationPolyfill<Content: View> {
    private var underlying: any UIContentConfiguration

    func margins(
        _ edges: Edge.Set = .all,
        _ length: CGFloat,
    ) -> UIHostingConfigurationPolyfill<Content> {
        if #available(iOS 16.0, *) {
            let newConf = (underlying as! UIHostingConfiguration<Content, EmptyView>)
                .margins(edges, length)
            return UIHostingConfigurationPolyfill(underlying: newConf)
        } else {
            return self
        }
    }
}

extension UIHostingConfigurationPolyfill: UIContentConfiguration {
    func makeContentView() -> any UIView & UIContentView {
        underlying.makeContentView()
    }

    func updated(
        for state: any UIConfigurationState
    ) -> UIHostingConfigurationPolyfill<Content> {
        return Self(underlying: underlying.updated(for: state))
    }
}

extension UIHostingConfigurationPolyfill {
    init(parentViewController: UIViewController, @ViewBuilder content: () -> Content) {
        if #available(iOS 16.0, *) {
            self.init(underlying: UIHostingConfiguration(content: content))
        } else {
            self.init(
                underlying: FallbackHostingConfiguration(
                    parentViewController: parentViewController,
                    content: content(),
                )
            )
        }
    }
}

private struct FallbackHostingConfiguration<Content: View>: UIContentConfiguration {
    unowned var parentViewController: UIViewController
    var content: Content

    func makeContentView() -> any UIView & UIContentView {
        let contentView = ContentView(configuration: self)
        contentView.layoutMargins = .zero
        return contentView
    }

    func updated(for state: any UIConfigurationState) -> FallbackHostingConfiguration {
        FallbackHostingConfiguration(parentViewController: parentViewController, content: content)
    }

    private final class ContentView: UIView, UIContentView {
        var configuration: UIContentConfiguration {
            get {
                currentConfiguration
            }
            set {
                guard let newConfiguration = newValue as? FallbackHostingConfiguration<Content> else {
                    fatalError("Expected configuration to be of type \(FallbackHostingConfiguration<Content>.self)")
                }
                currentConfiguration = newConfiguration
                hostingController.rootView = newConfiguration.content
                // Removing and re-adding the hosting controller from the view hierarchy and then invalidating
                // the intrinsic content size seems to be the only way to cause the UICollectionVIew and
                // UITableView to relayout the cells and update the heights.
                removeHostingControllerFromViewHierarchy()
                addHostingControllerToViewHierarchy()
                invalidateIntrinsicContentSize()
            }
        }

        private let hostingController: UIHostingController<Content>
        private var currentConfiguration: FallbackHostingConfiguration<Content>

        init(configuration: FallbackHostingConfiguration<Content>) {
            self.hostingController = UIHostingController(rootView: configuration.content)
            self.currentConfiguration = configuration
            super.init(frame: .zero)
            addHostingControllerToViewHierarchy()
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        isolated deinit {
            removeHostingControllerFromViewHierarchy()
        }

        func supports(_ configuration: any UIContentConfiguration) -> Bool {
            configuration is FallbackHostingConfiguration<Content>
        }

        private func addHostingControllerToViewHierarchy() {
            let parentViewController = currentConfiguration.parentViewController
            parentViewController.addChild(hostingController)
            hostingController.view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(hostingController.view)
            NSLayoutConstraint.activate([
                hostingController.view.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
                hostingController.view.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
                hostingController.view.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
                hostingController.view.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
            ])
            hostingController.didMove(toParent: parentViewController)
        }

        private func removeHostingControllerFromViewHierarchy() {
            hostingController.willMove(toParent: nil)
            hostingController.view.removeFromSuperview()
            hostingController.removeFromParent()
        }
    }
}
