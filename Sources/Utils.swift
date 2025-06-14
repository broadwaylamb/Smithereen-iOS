import Foundation
import SwiftUI

final class Box<T> {
    let value: T
    init(value: T) {
        self.value = value
    }
}

extension Box: Sendable where T: Sendable {}

extension Box: Equatable where T: Equatable {
	static func == (lhs: Box<T>, rhs: Box<T>) -> Bool {
		lhs.value == rhs.value
	}
}

struct AnyLocalizedError: LocalizedError {
    let error: Error
    var errorDescription: String? {
        error.localizedDescription
    }
}

extension HTTPCookie {
    var isExpired: Bool {
        expiresDate.map { $0 <= Date() } ?? false
    }
}

extension Optional where Wrapped: OptionSet, Wrapped.Element == Wrapped {
    mutating func insert(_ newValue: Wrapped) {
        var existing = self ?? []
        existing.insert(newValue)
        self = .some(existing)
    }
}
