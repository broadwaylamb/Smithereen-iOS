import Foundation
import SwiftUI
import SmithereenAPI
import Hammond

struct AnyLocalizedError: LocalizedError {
    let error: Error
    var errorDescription: String? {
        error.localizedDescription
    }
}

extension OAuth.AuthorizationCodeError: @retroactive LocalizedError {
    public var errorDescription: String? {
        let description: String.LocalizationValue
        switch self {
        case .stateMismatch:
            description = "Could not authenticate because of state mismatch."
        case .invalidURL:
            description = "Invalid redirection URL."
        }
        return String(localized: description)
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

extension Data {
    // TODO: Use base64URLAlphabet when it becomes available
    // https://forums.swift.org/t/pitch-adding-base64-urlencoding-and-omitting-padding-options-to-base64-encoding-and-decoding/77659
    func base64EncodedURLString() -> String {
        let encoded = base64EncodedString()
        let characters: [Character] = encoded.map {
            switch $0 {
            case "+": return "-" 
            case "/": return "_"
            default: return $0
            }
        }
        return String(characters)
    }
}

extension Locale {
    static let posix = Locale(identifier: "en_US_POSIX")
}
