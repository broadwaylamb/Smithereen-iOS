import Foundation
import SmithereenAPI

struct UserFriendlySmithereenAPIError: LocalizedError {
    var error: SmithereenAPIError

    var errorDescription: String? {
        switch error.code {
        case .tooManyRequestsPerSecond:
            String(localized: "Too many requests per second.", table: "ErrorMessages")
        case .floodControl:
            String(
                localized: """
                You are performing the same action too often. Please try again later.
                """,
                table: "ErrorMessages"
            )
        case .accessDenied:
            String(localized: "Access denied.", table: "ErrorMessages")
        default:
            error.message
        }
    }
}
