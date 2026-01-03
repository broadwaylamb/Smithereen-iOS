import SwiftUI

struct AppStorageKey<Value> {
    fileprivate var name: String
    fileprivate var defaultValue: Value
}

extension AppStorageKey: Sendable where Value: Sendable {}

extension AppStorage where Value == Bool {
    init(_ key: AppStorageKey<Bool>, store: UserDefaults? = nil) {
        self.init(wrappedValue: key.defaultValue, key.name, store: store)
    }
}

extension AppStorageKey<String> {
    static let smithereenInstance = Self(name: "smithereenInstance", defaultValue: "")
}

extension AppStorageKey<Bool> {
    static let roundProfilePictures = Self(
        name: "smithereen.roundProfilePictures",
        defaultValue: false,
    )
}
