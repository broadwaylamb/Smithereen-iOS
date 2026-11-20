import SwiftUI
import SmithereenAPI

@MainActor
final class AsyncImageViewModel: ObservableObject {
    enum Phase {
        case success(UIImage, ImageLocation)
        case failure(any Swift.Error, blurhash: UIImage?)
        case pending(blurhash: UIImage?, ImageLocation)
        case empty(blurhash: UIImage?)

        var image: UIImage? {
            switch self {
            case .success(let image, _):
                image
            case .failure(_, let blurhash):
                blurhash
            case .pending(let blurhash, _):
                blurhash
            case .empty(let blurhash):
                blurhash
            }
        }
    }

    enum Error: Swift.Error {
        case invalidResponse
        case invalidData
    }

    @Published private(set) var phase: Phase
    private let cachePolicy: NSURLRequest.CachePolicy
    private var loadingTask: Task<Void, Never>?
    private var sizes: ImageSizes

    fileprivate init(
        sizes: ImageSizes,
        phase: Phase,
        cachePolicy: NSURLRequest.CachePolicy,
    ) {
        self.sizes = sizes
        self.phase = phase
        self.cachePolicy = cachePolicy
    }

    init(
        sizes: ImageSizes,
        blurHash: BlurHash? = nil,
        cachePolicy: NSURLRequest.CachePolicy = .returnCacheDataElseLoad,
    ) {
        self.sizes = sizes
        self.cachePolicy = cachePolicy
        let blurHashImage = blurHash.flatMap {
            UIImage(blurHash: $0, aspectRatio: sizes.aspectRatio)
        }
        self.phase = .empty(blurhash: blurHashImage)
    }

    var currentImage: UIImage? {
        phase.image
    }

    private func setPhaseAnimated(_ newPhase: Phase) {
        withAnimation(.easeIn(duration: 0.2)) {
            phase = newPhase
        }
    }

    private func setErrorState(_ error: Swift.Error) {
        switch phase {
        case .success:
            return // Do nothing, leave the existing image
        case .failure(_, let blurhash),
                .pending(let blurhash, _),
                .empty(let blurhash):
            setPhaseAnimated(
                .failure(
                    Error.invalidData,
                    blurhash: blurhash,
                )
            )
        }
    }

    nonisolated func loadImage(
        location: ImageLocation?,
        displayScale: CGFloat,
    ) async {
        switch location {
        case .remote(let url):
            do {
                let urlRequest = URLRequest(url: url, cachePolicy: cachePolicy)
                let (data, response) = try await URLSession
                    .cacheableMediaURLSession
                    .data(for: urlRequest)
                if response.statusCode.category == .success {
                    if let image = UIImage(data: data, scale: displayScale) {
                        await setPhaseAnimated(.success(image, .remote(url)))
                        return
                    }
                    await setErrorState(Error.invalidData)
                } else {
                    await setErrorState(Error.invalidResponse)
                }
            } catch {
                await setErrorState(error)
            }
        case .bundled(let resource):
            await setPhaseAnimated(
                .success(UIImage(resource: resource), .bundled(resource))
            )
        case nil:
            return
        }
    }

    func loadImage(
        fitting size: CGSize,
        displayScale: CGFloat,
        completion: (@MainActor (Phase) -> Void)? = nil,
    ) {
        let location = sizes.sizeThatFits(size, scale: displayScale)
        switch phase {
        case .success(_, let previousLocation),
                .pending(_, let previousLocation):
            if location == previousLocation {
                completion?(phase)
                return
            }
        default:
            break
        }
        loadingTask = Task { [weak self] in
            await self?.loadImage(location: location, displayScale: displayScale)
            if let self {
                self.loadingTask = nil
                completion?(self.phase)
            }
        }
    }

    func cancelLoading() {
        loadingTask?.cancel()
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

    @StateObject private var phaseHolder: AsyncImageViewModel
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

        let scale = Environment(\.displayScale).wrappedValue

        func initializePhase() -> AsyncImageViewModel.Phase {
            guard let location = sizes.sizeThatFits(size, scale: scale) else {
                return .empty(
                    blurhash: blurHash.flatMap {
                        UIImage(blurHash: $0, aspectRatio: aspectRatio)
                    }
                )
            }
            switch location {
            case .remote(let url):
                let urlRequest = URLRequest(url: url)
                if cachePolicy != .reloadIgnoringLocalCacheData,
                   let cachedResponse = URLCache
                    .smithereenMediaCache
                    .cachedResponse(for: urlRequest),
                   let image = UIImage(data: cachedResponse.data, scale: scale)
                {
                    return .success(image, location)
                } else {
                    return .pending(
                        blurhash: blurHash.flatMap {
                            UIImage(blurHash: $0, aspectRatio: aspectRatio)
                        },
                        location,
                    )
                }
            case .bundled(let resource):
                return .success(UIImage(resource: resource), location)
            }
        }

        _phaseHolder = StateObject(
            wrappedValue: AsyncImageViewModel(
                sizes: sizes,
                phase: initializePhase(),
                cachePolicy: cachePolicy,
            )
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
        case .success(let image, _):
            content(Image(uiImage: image))
                .onChange(of: location) { _ in
                    phaseHolder.loadImage(fitting: viewportSize, displayScale: displayScale)
                }
        case .failure(_, let blurhash):
            blurHashOrPlaceholder(blurhash.map(Image.init(uiImage:)))
                .onChange(of: location) { _ in
                    phaseHolder.loadImage(fitting: viewportSize, displayScale: displayScale)
                }
        case .pending(let blurhash, _):
            blurHashOrPlaceholder(blurhash.map(Image.init(uiImage:)))
                .task(id: location) {
                    await phaseHolder.loadImage(location: location, displayScale: displayScale)
                }
        case .empty(let blurhash):
            blurHashOrPlaceholder(blurhash.map(Image.init(uiImage:)))
                .onChange(of: location) { _ in
                    phaseHolder.loadImage(fitting: viewportSize, displayScale: displayScale)
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
        self.init(
            size: size,
            sizes: sizes,
            cachePolicy: cachePolicy,
            content: content,
            placeholder: placeholder,
        )
    }
}

extension UIImage {
    fileprivate convenience init?(blurHash: BlurHash, aspectRatio: CGFloat) {
        let resolution: CGFloat = 32
        self.init(
            blurHash: blurHash,
            resolution: CGSize(
                width: aspectRatio > 1 ? resolution * aspectRatio : resolution,
                height: aspectRatio > 1 ? resolution : resolution / aspectRatio,
            ),
            punch: 1.1,
        )
    }
}
