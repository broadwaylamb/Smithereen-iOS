import Foundation
import Hammond

/// A wrapper for `DecodingError` that also renders
/// the corresponding `URLRequest` and `HTTPURLResponse`.
struct ExtendedDecodingError: TechnicalError, LocalizedError {
    var request: URLRequest
    var response: HTTPURLResponse
    var responseData: Data
    var error: DecodingError

    var errorDescription: String? {
        error.localizedDescription
    }

    private var prettyPrintedResponseData: String {
        do {
            let object = try JSONSerialization
                .jsonObject(with: responseData)
            let prettyPrinted = try JSONSerialization
                .data(withJSONObject: object, options: .prettyPrinted)
            return String(decoding: prettyPrinted, as: UTF8.self)
        } catch {
            return String(decoding: responseData, as: UTF8.self)
        }
    }

    var technicalInfo: String {
        """
        Could not deserialize response for HTTP request:
        \(request.render())
        
        HTTP response:
        \(response.render())
        
        Response data (pretty-printed):
        \(prettyPrintedResponseData)
        
        Error details:
        \(error.technicalInfo)
        """
    }
}

extension URLRequest {
    // Taken from swift-snapshot-testing
    // https://github.com/pointfreeco/swift-snapshot-testing/blob/27b92be8136abe7de7cacede6f32fab43191f3c1/Sources/SnapshotTesting/Snapshotting/URLRequest.swift#L28
    // and slightly adjusted.
    fileprivate func render() -> String {
        let method = "\(httpMethod ?? "GET") \(url?.absoluteString ?? "(null)")"

        var fields = allHTTPHeaderFields ?? [:]
        if fields["Authorization"] != nil {
            fields["Authorization"] = "Bearer REDACTED"
        }

        let headers = fields
            .map { key, value in "\(key): \(value)" }
            .sorted()

        let body = httpBody.map { ["\n\(String(decoding: $0, as: UTF8.self))"] } ?? []

        return ([method] + headers + body).joined(separator: "\n")
    }
}

extension HTTPURLResponse {
    fileprivate func render() -> String {
        let status = "Status: \(String(reflecting: statusCode as HTTPStatusCode))"
        let headers = allHeaderFields
            .map { key, value in "\(key): \(value)" }
            .sorted()
        return ([status] + headers).joined(separator: "\n")
    }
}
