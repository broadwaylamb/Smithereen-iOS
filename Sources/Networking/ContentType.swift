import Foundation

struct ContentType: Hashable {
    fileprivate let type: String
    fileprivate let subtype: String

    var rawValue: String {
        "\(type)/\(subtype)"
    }

    struct _ApplicationBuilder {
        private static let type = "application"

        let formURLEncoded = ContentType(type: type, subtype: "x-www-form-urlencoded")
    }

    static let application = _ApplicationBuilder()

    struct _TextBuilder {
        private static let type = "text"

        let html = ContentType(type: type, subtype: "html")
    }

    static let text = _TextBuilder()
}

extension URLRequest {
    mutating func setContentType(_ contentType: ContentType?) {
        setValue(contentType?.rawValue, forHTTPHeaderField: "Content-Type")
    }

    mutating func setAccept(_ contentType: ContentType?) {
        setValue(contentType?.rawValue, forHTTPHeaderField: "Accept")
    }
}
