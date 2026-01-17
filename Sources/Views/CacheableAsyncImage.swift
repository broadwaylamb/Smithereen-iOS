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
    @Published var phase: CacheableAsyncImagePhase

    init(phase: CacheableAsyncImagePhase) {
        self.phase = phase
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

        _phaseHolder = StateObject(
            wrappedValue: PhaseHolder(phase: .pending(blurhash: loadBlurHash()))
        )
    }

    private var location: ImageLocation? {
        sizes.sizeThatFits(viewportSize, scale: displayScale)
    }

    private func setPhaseAnimated(_ newPhase: CacheableAsyncImagePhase) {
        withAnimation(.easeIn(duration: 0.2)) {
            phaseHolder.phase = newPhase
        }
    }

    private func setErrorState(_ error: Error) {
        switch phaseHolder.phase {
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

    private func loadImage() async {
        switch location {
        case .remote(let url):
            do {
                let urlRequest = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)
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

    @ViewBuilder
    private func blurHashOrPlaceholder(_ blurhash: Image?) -> some View {
        if let blurhash {
            content(blurhash)
        } else {
            placeholder()
        }
    }

    @ViewBuilder
    private var image: some View {
        switch phaseHolder.phase {
        case .success(let image):
            content(image)
        case .failure(_, let blurhash):
            blurHashOrPlaceholder(blurhash)
        case .pending(let blurhash):
            blurHashOrPlaceholder(blurhash)
        case .empty(let blurhash):
            blurHashOrPlaceholder(blurhash)
        }
    }

    var body: some View {
        image
            .task(id: location) {
                await loadImage()
            }
    }
}

private func imageFromData(_ data: Data, scale: CGFloat) -> Image? {
    UIImage(data: data, scale: scale).map(Image.init(uiImage:))
}
