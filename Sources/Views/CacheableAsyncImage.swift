import SwiftUI
import SmithereenAPI

enum CacheableAsyncImageError: Error {
    case invalidResponse
    case invalidData
}

private enum CacheableAsyncImagePhase {
    case success(Image)
    case failure(any Error, blurhash: Image?)
    case pending(URLRequest, blurhash: Image?)
    case empty(blurhash: Image?)
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

    @StateObject private var phaseHolder: PhaseHolder

    init(
        _ location: ImageLocation?,
        blurHash: BlurHash? = nil,
        aspectRatio: CGFloat,
        scale: CGFloat = 2,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder,
    ) {
        self.scale = scale
        self.content = content
        self.placeholder = placeholder

        func loadBlurHash() -> Image? {
            guard let blurHash else { return nil }
            let resolution: CGFloat = 32
            return UIImage(
                blurHash: blurHash,
                resolution: CGSize(
                    width: aspectRatio > 1 ? resolution * aspectRatio : resolution,
                    height: aspectRatio > 1 ? resolution : resolution / aspectRatio,
                ),
                punch: 1.1,
            ).map(Image.init(uiImage:))
        }

        func initializePhase() -> CacheableAsyncImagePhase {
            switch location {
            case .remote(let url):
                let urlRequest = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)
                if let cachedResponse = URLCache
                    .smithereenMediaCache
                    .cachedResponse(for: urlRequest),
                   let image = imageFromData(cachedResponse.data, scale: scale)
                {
                    return .success(image)
                } else {
                    return .pending(urlRequest, blurhash: loadBlurHash())
                }
            case .bundled(let resource):
                return .success(Image(resource))
            case nil:
                return .empty(blurhash: loadBlurHash())
            }
        }

        _phaseHolder = StateObject(wrappedValue: PhaseHolder(phase: initializePhase()))
    }

    private func loadImage(
        _ urlRequest: URLRequest,
        blurhash: Image?
    ) async {
        do {
            let (data, response) = try await URLSession
                .cacheableMediaURLSession
                .data(for: urlRequest)
            if response.statusCode.category == .success {
                phaseHolder.phase = imageFromData(data, scale: scale)
                    .map(CacheableAsyncImagePhase.success)
                    ?? .failure(CacheableAsyncImageError.invalidData, blurhash: blurhash)
            } else {
                phaseHolder.phase =
                    .failure(CacheableAsyncImageError.invalidResponse, blurhash: blurhash)
            }
        } catch {
            phaseHolder.phase = .failure(error, blurhash: blurhash)
        }
    }

    @ViewBuilder
    private func blurHashOrPlaceholder(_ blurhash: Image?) -> some View {
        if let blurhash {
            content(blurhash)
        } else {
            placeholder()
        }
    }

    var body: some View {
        switch phaseHolder.phase {
        case .success(let image):
            content(image)
        case .failure(_, let blurhash):
            blurHashOrPlaceholder(blurhash)
        case .pending(let urlRequest, let blurhash):
            blurHashOrPlaceholder(blurhash)
                .task {
                    await loadImage(urlRequest, blurhash: blurhash)
                }
        case .empty(let blurhash):
            blurHashOrPlaceholder(blurhash)
        }
    }
}

private func imageFromData(_ data: Data, scale: CGFloat) -> Image? {
    UIImage(data: data, scale: scale).map(Image.init(uiImage:))
}
