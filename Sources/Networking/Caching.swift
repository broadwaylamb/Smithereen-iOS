import Foundation

extension URLCache {
    static let smithereenMediaCache: URLCache = URLCache(
        memoryCapacity: 20 * 1024 * 1024, // 20 megabytes
        diskCapacity: 512 * 1024 * 1024, // 512 megabytes
    )
}

extension URLSession {
    static let cacheableMediaURLSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = .smithereenMediaCache
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        return URLSession(configuration: configuration)
    }()
}
