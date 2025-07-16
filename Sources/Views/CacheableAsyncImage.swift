import SwiftUI

enum CacheableAsyncImageError: Error {
    case invalidResponse
    case invalidData
}

private enum CacheableAsyncImagePhase {
    case success(Image)
    case failure(any Error)
    case empty
}

@MainActor
private final class PhaseHolder: ObservableObject {
    @Published var phase: CacheableAsyncImagePhase = .empty
}

struct CacheableAsyncImage<Content: View, Placeholder: View>: View {
    private var urlRequest: URLRequest?
    private var scale: CGFloat

    private var content: (Image) -> Content

    private var placeholder: () -> Placeholder

    @StateObject private var phaseHolder = PhaseHolder()

    init(
        _ location: ImageLocation?,
        scale: CGFloat = 2,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder,
    ) {
        let url: URL? = if case .remote(let url) = location {
            url
        } else {
            nil
        }
        self.init(url: url, scale: scale, content: content, placeholder: placeholder)
        if case .bundled(let resource) = location {
            phaseHolder.phase = .success(Image(resource))
        }
    }

    init(
        url: URL?,
        scale: CGFloat = 2,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder,
    ) {
        self.scale = scale
        self.content = content
        self.placeholder = placeholder
        guard let url = url else { return }
        let urlRequest = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)
        self.urlRequest = urlRequest
        if let cachedResponse = URLCache
            .smithereenMediaCache
            .cachedResponse(for: urlRequest),
           let image = imageFromData(cachedResponse.data, scale: scale)
        {
            phaseHolder.phase = .success(image)
        }
    }

    private func loadImage() async {
        do {
            let (data, response) = try await URLSession
                .cacheableMediaURLSession
                .data(for: urlRequest!)
            if response.statusCode.category == .success {
                phaseHolder.phase = imageFromData(data, scale: scale)
                    .map(CacheableAsyncImagePhase.success)
                        ?? .failure(CacheableAsyncImageError.invalidData)
            } else {
                phaseHolder.phase = .failure(CacheableAsyncImageError.invalidResponse)
            }
        } catch {
            phaseHolder.phase = .failure(error)
        }
    }

    var body: some View {
        switch phaseHolder.phase {
        case .success(let image):
            content(image)
        case .empty:
            placeholder().task(loadImage)
        case .failure(_):
            placeholder()
        }
    }
}

private func imageFromData(_ data: Data, scale: CGFloat) -> Image? {
    UIImage(data: data, scale: scale).map(Image.init(uiImage:))
}
