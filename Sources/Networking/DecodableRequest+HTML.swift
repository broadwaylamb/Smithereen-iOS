import Hammond
import Foundation
import SwiftSoup

protocol DecodableRequestProtocol: Hammond.DecodableRequestProtocol, Sendable
    where ServerError == Smithereen.ServerError,
          Result: Sendable
{
    associatedtype ResponseBody = Document

    static var contentType: ContentType { get }

    static var accept: ContentType { get }
}

extension DecodableRequestProtocol {
    static var contentType: ContentType {
        .application.formURLEncoded
    }

    static var accept: ContentType {
        .text.html
    }
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

protocol IgnoreRedirects: RequestProtocol {}

struct PictureFromHTML {
    var url: URL?
    var altText: String?
    var blurHash: RGBAColor?
}

private let blurHashRegex =
    try! NSRegularExpression(pattern: #"background-color: #([a-fA-F0-9]{6})"#)

extension DecodableRequestProtocol {
    static func parsePicture(
        _ element: Element
    ) -> PictureFromHTML {
        do {
            let img = try element.select("img").first()
            let altText = try img?.attr("alt")
            let style = try img?.attr("style")
            let blurHash = style.flatMap {
                blurHashRegex.firstMatch(in: $0, captureGroup: 1)
            }?.flatMap(RGBAColor.init(cssHex:))
            for resource in try element.select("source") {
                if try resource.attr("type") != "image/webp" {
                    continue
                }
                let srcsets = try resource.attr("srcset")
                    .split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespaces) }

                for srcset in srcsets {
                    if srcset.hasSuffix(" 2x") {
                        let url = URL(string: String(srcset.prefix(srcset.count - 3)))
                        return PictureFromHTML(url: url, altText: altText, blurHash: blurHash)
                    }
                }
            }
        } catch {
            // If there is an error, we ignore it and return nil
        }
        return PictureFromHTML()
    }
}
