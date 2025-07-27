import Hammond
import Foundation
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

private let jsonDecoder: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return decoder
}()

extension DecodableRequestProtocol where ResponseBody == Data, Result: Decodable {
    static func deserializeError(from body: ResponseBody) throws -> ServerError {
        // TODO: When we switch to using the API, actually deserialize the error
        throw ServerError.defaultError(for: .noContent)
    }

    static func deserializeResult(from body: ResponseBody) throws -> Result {
        try jsonDecoder.decode(Result.self, from: body)
    }
}

protocol RequiresCSRF: RequestProtocol {}
