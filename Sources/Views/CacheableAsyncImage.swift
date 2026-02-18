import SwiftUI
import SmithereenAPI

enum CacheableAsyncImageError: Error {
    case invalidResponse
    case invalidData
}

private enum CacheableAsyncImagePhase {
    case success(Image)
    case failure(any Error, blurhash: Image?)
    case pending(blurhash: Image?)
    case empty(blurhash: Image?)
}

@MainActor
private final class PhaseHolder: ObservableObject {
    private let cachePolicy: NSURLRequest.CachePolicy
    @Published var phase: CacheableAsyncImagePhase

    init(phase: CacheableAsyncImagePhase, cachePolicy: NSURLRequest.CachePolicy) {
        self.cachePolicy = cachePolicy
        self.phase = phase
    }

    private func setPhaseAnimated(_ newPhase: CacheableAsyncImagePhase) {
        withAnimation(.easeIn(duration: 0.2)) {
            phase = newPhase
        }
    }

    private func setErrorState(_ error: Error) {
        switch phase {
        case .success:
            return // Do nothing, leave the existing image
        case .failure(_, let blurhash),
                .pending(let blurhash),
                .empty(let blurhash):
            setPhaseAnimated(
                .failure(
                    CacheableAsyncImageError.invalidData,
                    blurhash: blurhash,
                )
            )
        }
    }

    func loadImage(location: ImageLocation?, displayScale: CGFloat) async {
        switch location {
        case .remote(let url):
            do {
                let urlRequest = URLRequest(url: url, cachePolicy: cachePolicy)
                let (data, response) = try await URLSession
                    .cacheableMediaURLSession
                    .data(for: urlRequest)
                if response.statusCode.category == .success {
                    if let image = imageFromData(data, scale: displayScale) {
                        setPhaseAnimated(.success(image))
                        return
                    }
                    setErrorState(CacheableAsyncImageError.invalidData)
                } else {
                    setErrorState(CacheableAsyncImageError.invalidResponse)
                }
            } catch {
                setErrorState(error)
            }
        case .bundled(let resource):
            setPhaseAnimated(.success(Image(resource)))
        case nil:
            return
        }
    }

    private var loadingTask: Task<Void, Never>?

    func loadImage(location: ImageLocation?, displayScale: CGFloat) {
        loadingTask = Task { [unowned self] in
            await self.loadImage(location: location, displayScale: displayScale)
            self.loadingTask = nil
        }
    }

    deinit {
        loadingTask?.cancel()
    }
}

struct CacheableAsyncImage<Content: View, Placeholder: View>: View {
    private var viewportSize: CGSize
    private var sizes: ImageSizes
    private var content: (Image) -> Content
    private var placeholder: () -> Placeholder

    @StateObject private var phaseHolder: PhaseHolder
    @Environment(\.displayScale) private var displayScale

    init(
        size: CGSize,
        sizes: ImageSizes,
        blurHash: BlurHash? = nil,
        cachePolicy: NSURLRequest.CachePolicy = .returnCacheDataElseLoad,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder,
    ) {
        self.viewportSize = size
        self.sizes = sizes
        self.content = content
        self.placeholder = placeholder

        let aspectRatio = sizes.aspectRatio
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

        let scale = Environment(\.displayScale).wrappedValue

        func initializePhase() -> CacheableAsyncImagePhase {
            switch sizes.sizeThatFits(size, scale: scale) {
            case .remote(let url):
                let urlRequest = URLRequest(url: url)
                if cachePolicy != .reloadIgnoringLocalCacheData,
                   let cachedResponse = URLCache
                    .smithereenMediaCache
                    .cachedResponse(for: urlRequest),
                   let image = imageFromData(cachedResponse.data, scale: scale)
                {
                    return .success(image)
                } else {
                    return .pending(blurhash: loadBlurHash())
                }
            case .bundled(let resource):
                return .success(Image(resource))
            case nil:
                return .empty(blurhash: loadBlurHash())
            }
        }

        _phaseHolder = StateObject(
            wrappedValue: PhaseHolder(phase: initializePhase(), cachePolicy: cachePolicy)
        )
    }

    private var location: ImageLocation? {
        sizes.sizeThatFits(viewportSize, scale: displayScale)
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
                .onChange(of: location) {
                    phaseHolder.loadImage(location: $0, displayScale: displayScale)
                }
        case .failure(_, let blurhash):
            blurHashOrPlaceholder(blurhash)
                .onChange(of: location) {
                    phaseHolder.loadImage(location: $0, displayScale: displayScale)
                }
        case .pending(let blurhash):
            blurHashOrPlaceholder(blurhash)
                .task(id: location) {
                    await phaseHolder
                        .loadImage(location: location, displayScale: displayScale)
                }
        case .empty(let blurhash):
            blurHashOrPlaceholder(blurhash)
                .onChange(of: location) {
                    phaseHolder.loadImage(location: $0, displayScale: displayScale)
                }
        }
    }
}

extension CacheableAsyncImage {
    init(
        size: CGSize,
        url: URL,
        cachePolicy: NSURLRequest.CachePolicy = .returnCacheDataElseLoad,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder,
    ) {
        var sizes = ImageSizes()
        sizes.append(size: .infinity, url: url)
        self.init(size: size, sizes: sizes, content: content, placeholder: placeholder)
    }
}

private func imageFromData(_ data: Data, scale: CGFloat) -> Image? {
    UIImage(data: data, scale: scale).map(Image.init(uiImage:))
}
