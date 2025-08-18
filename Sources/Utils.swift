import Foundation
import Hammond
import SwiftUI

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

extension NSRegularExpression {
    func firstMatch(in s: String) -> NSTextCheckingResult? {
        firstMatch(
            in: s,
            range: NSRange(s.startIndex..<s.endIndex, in: s)
        )
    }

    func firstMatch(in s: String, captureGroup: Int) -> Substring? {
        let tcr = firstMatch(in: s)
        return tcr?.captureGroup(captureGroup, in: s)
    }
}

extension NSTextCheckingResult {
    func captureGroup<S: StringProtocol>(_ n: Int, in s: S) -> S.SubSequence? {
        if numberOfRanges < n {
            return nil
        }
        return Range(range(at: n), in: s).map { s[$0] }
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

// Make only available in previews
extension String {
    /// Helps to avoid strings from previews appearing in the localization string catalog.
    var excludedFromLocalization: LocalizedStringKey {
        LocalizedStringKey(stringLiteral: self)
    }
}
