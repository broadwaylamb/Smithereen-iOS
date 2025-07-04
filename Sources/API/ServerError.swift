import Foundation
import Hammond

struct ServerError {
    var statusCode: HTTPStatusCode
}

extension ServerError: ServerErrorProtocol {
    static func defaultError(for statusCode: HTTPStatusCode) -> ServerError {
        ServerError(statusCode: statusCode)
    }
}

extension ServerError: LocalizedError {
    var errorDescription: String? {
        HTTPURLResponse.localizedString(forStatusCode: statusCode.rawValue)
    }
}
