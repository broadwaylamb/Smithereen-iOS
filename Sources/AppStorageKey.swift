import SwiftUI

struct AppStorageKey<Value>: RawRepresentable {
    var rawValue: String
}

extension AppStorage where Value == String {
    init(wrappedValue: String, _ key: AppStorageKey<String>, store: UserDefaults? = nil) {
        self.init(wrappedValue: wrappedValue, key.rawValue, store: store)
    }
}

extension AppStorageKey<String> {
    static let smithereenInstance = Self(rawValue: "smithereenInstance")
}
