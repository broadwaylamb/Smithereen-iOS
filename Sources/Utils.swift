import Foundation

class Box<T> {
    var value: T
    init(value: T) {
        self.value = value
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
