import Foundation
import Hammond
import SwiftUI
import SmithereenAPI

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

extension URLResponse {
    var statusCode: HTTPStatusCode {
        HTTPStatusCode(rawValue: (self as! HTTPURLResponse).statusCode)
    }
}

extension CGSize {
    var aspectRatio: CGFloat {
        width / height
    }
}

extension String {
    /// Helps to avoid strings from previews appearing in the localization string catalog.
    var excludedFromLocalization: LocalizedStringKey {
        LocalizedStringKey(stringLiteral: self)
    }
}

extension Error {
    var isCancellationError: Bool {
        if self is CancellationError { return true }
        let nsError = self as NSError
        if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
            return true
        }
        return false
    }
}

extension String {
    var isBlank: Bool {
        isEmpty || allSatisfy { $0.isWhitespace }
    }
}

extension User {
    var nameComponents: PersonNameComponents {
        PersonNameComponents(
            givenName: firstName,
            middleName: nickname,
            familyName: lastName,
        )
    }
}

extension Birthday {
    var dateComponents: DateComponents {
        DateComponents(
            calendar: Calendar(identifier: .gregorian),
            year: year,
            month: month,
            day: day,
        )
    }
}

