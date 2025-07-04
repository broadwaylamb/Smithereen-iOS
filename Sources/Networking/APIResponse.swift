import Hammond
import SwiftSoup

struct APIResponse: ResponseProtocol {
    var statusCode: HTTPStatusCode
    var body: Document
}
