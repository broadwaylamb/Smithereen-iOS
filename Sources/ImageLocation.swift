import Foundation

enum ImageLocation: Equatable {
    case remote(URL)
    case bundled(ImageResource)
}

extension ImageLocation: Decodable {
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let url = try container.decode(URL.self)
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        else {
            throw
                DecodingError
                .dataCorrupted(
                    .init(
                        codingPath: container.codingPath,
                        debugDescription: "Invalid URL",
                    )
                )
        }
        if components.scheme == "bundled" {
            guard let host = components.host else {
                throw
                    DecodingError
                    .dataCorrupted(
                        .init(
                            codingPath: container.codingPath,
                            debugDescription: "Missing host in 'bundled://' URL",
                        )
                    )
            }
            self = .bundled(ImageResource(name: host, bundle: .main))
        } else {
            self = .remote(url)
        }
    }
}

extension ImageLocation: Encodable {
    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .remote(let url):
            try container.encode(url)
        case .bundled(let imageResource):
            throw EncodingError.invalidValue(
                imageResource,
                .init(
                    codingPath: container.codingPath,
                    debugDescription: "Bundled image location is not encodable",
                )
            )
        }
    }
}
