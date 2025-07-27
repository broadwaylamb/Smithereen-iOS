import Hammond
import SwiftSoup

protocol DecodableRequestProtocol: Hammond.DecodableRequestProtocol, Sendable
    where ServerError == Smithereen.ServerError,
          Result: Sendable
{
    associatedtype ResponseBody = Document
}

extension DecodableRequestProtocol where ResponseBody == Document {
    static func deserializeError(from body: ResponseBody) throws -> ServerError {
        // This error will not be used anywhere
        throw ServerError.defaultError(for: .noContent)
    }
}

protocol RequiresCSRF: RequestProtocol {}
