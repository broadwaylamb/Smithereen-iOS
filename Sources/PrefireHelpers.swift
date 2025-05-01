import SwiftUI

extension View {
    // Prefire only looks for a call with this name, no matter where the function
    // is defined.
    func prefireIgnored() -> Self {
        return self
    }
}
