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


extension HTTPURLResponse {
    fileprivate func render() -> String {
        let status = "Status: \(String(reflecting: statusCode as HTTPStatusCode))"
        let headers = allHeaderFields
            .map { key, value in "\(key): \(value)" }
            .sorted()
        return ([status] + headers).joined(separator: "\n")
    }
}
