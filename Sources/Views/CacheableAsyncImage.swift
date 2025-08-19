import SwiftUI

enum CacheableAsyncImageError: Error {
    case invalidResponse
    case invalidData
}

private enum CacheableAsyncImagePhase {
    case success(Image)
    case failure(any Error)
    case pending(URLRequest)
    case empty
}

@MainActor
private final class PhaseHolder: ObservableObject {
    @Published var phase: CacheableAsyncImagePhase

    init(phase: CacheableAsyncImagePhase) {
        self.phase = phase
    }
}

struct CacheableAsyncImage<Content: View, Placeholder: View>: View {
    private var scale: CGFloat

    private var content: (Image) -> Content

    private var placeholder: () -> Placeholder

    @ObservedObject private var phaseHolder: PhaseHolder

    init(
        _ location: ImageLocation?,
        scale: CGFloat = 2,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder,
    ) {
        self.scale = scale
        self.content = content
        self.placeholder = placeholder
        let phase: CacheableAsyncImagePhase
        switch location {
        case .remote(let url):
            let urlRequest = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)
            if let cachedResponse = URLCache
                .smithereenMediaCache
                .cachedResponse(for: urlRequest),
               let image = imageFromData(cachedResponse.data, scale: scale)
            {
                phase = .success(image)
            } else {
                phase = .pending(urlRequest)
            }
        case .bundled(let resource):
            phase = .success(Image(resource))
        case nil:
            phase = .empty
        }
        _phaseHolder = ObservedObject(wrappedValue: PhaseHolder(phase: phase))
    }

    private func loadImage(_ urlRequest: URLRequest) async {
        do {
            let (data, response) = try await URLSession
                .cacheableMediaURLSession
                .data(for: urlRequest)
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
        case .failure(_):
            placeholder()
        case .pending(let urlRequest):
            placeholder().task { await loadImage(urlRequest) }
        case .empty:
            placeholder()
        }
    }
}

private func imageFromData(_ data: Data, scale: CGFloat) -> Image? {
    UIImage(data: data, scale: scale).map(Image.init(uiImage:))
}
