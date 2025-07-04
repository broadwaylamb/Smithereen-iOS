import Hammond
import SwiftSoup

protocol DecodableRequestProtocol: Hammond.DecodableRequestProtocol
    where ServerError == Smithereen.ServerError
{
    associatedtype ResponseBody = Document
}

extension DecodableRequestProtocol where ResponseBody == Document {
    static func deserializeError(from body: ResponseBody) throws -> ServerError {
        // This error will not be used anywhere
        throw ServerError.defaultError(for: .noContent)
    }
}
