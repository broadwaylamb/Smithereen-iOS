import Foundation
import GRDB

struct DatabaseError: TechnicalError {
    var wrapped: GRDB.DatabaseError

    var technicalInfo: String {
        wrapped.expandedDescription
    }
}

extension DatabaseError: LocalizedError {
    var errorDescription: String? {
        String(
            localized: """
            Database integrity error. Please report this bug to the application developer.
            """,
            table: "ErrorMessages",
        )
    }
}
