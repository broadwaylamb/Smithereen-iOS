import Foundation

extension URLRequest {
    // Taken from swift-snapshot-testing
    // https://github.com/pointfreeco/swift-snapshot-testing/blob/27b92be8136abe7de7cacede6f32fab43191f3c1/Sources/SnapshotTesting/Snapshotting/URLRequest.swift#L28
    // and slightly adjusted.
    func render() -> String {
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
