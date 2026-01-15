import SwiftUI
import MediaGridLayout
import SmithereenAPI

struct PostAttachmentsView: View {
    private var images: [ImageAttachment] = []
    private var hasVideoAttachments = false
    private var hasAudioAttachments = false
    private var hasPolls = false
    private let unsupportedMessagePadding: CGFloat

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject private var palette: PaletteHolder

    init(_ attachments: [Attachment], unsupportedMessagePadding: CGFloat = 0) {
        self.unsupportedMessagePadding = unsupportedMessagePadding
        for attachment in attachments {
            switch attachment {
            case .photo(let photo):
                images.append(
                    ImageAttachment(
                        aspectRatio: photo.aspectRatio,
                        blurHash: photo.blurhash,
                    )
                )
            case .graffiti(let graffiti):
                images.append(
                    ImageAttachment(
                        aspectRatio: CGFloat(graffiti.width) / CGFloat(graffiti.height),
                    )
                )
            case .video:
                hasVideoAttachments = true
            case .audio:
                hasAudioAttachments = true
            case .poll:
                hasPolls = true
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack(spacing: 0) {
                Spacer(minLength: 0)
                MediaGridLayout(spacing: 2) {
                    ForEach(images.indexed(), id: \.offset) { (_, image) in
                        let placeholder = palette.loadingImagePlaceholder
                        let cornerRadius = horizontalSizeClass == .regular ? 2.5 : 0
                        let aspectRatio = image.aspectRatio
                        // We put the image into an overlay because otherwise it won't be
                        // clipped inside the grid.
                        Color.clear
                            .overlay {
                                // TODO: Use the correct URL based on the size
                                CacheableAsyncImage(
                                    nil,
                                    blurHash: image.blurHash,
                                    aspectRatio: aspectRatio,
                                ) { image in
                                    image.resizable()
                                } placeholder: {
                                    placeholder
                                }
                                .aspectRatio(image.aspectRatio, contentMode: .fill)
                            }
                            .aspectRatioForGridLayout(aspectRatio)
                            .cornerRadius(cornerRadius)
                            .clipped()
                    }
                }
                Spacer(minLength: 0)
            }
            .frame(maxHeight: 510)

            if hasVideoAttachments {
                Text("Video attachments are not supported yet")
                    .italic()
                    .foregroundStyle(.gray)
                    .padding(.horizontal, unsupportedMessagePadding)
            }
            if hasAudioAttachments {
                Text("Audio attachments are not supported yet")
                    .italic()
                    .foregroundStyle(.gray)
                    .padding(.horizontal, unsupportedMessagePadding)
            }
            if hasPolls {
                Text("Polls are not supported yet")
                    .italic()
                    .foregroundStyle(.gray)
                    .padding(.horizontal, unsupportedMessagePadding)
            }
        }
    }
}

private struct ImageAttachment {
    var aspectRatio: CGFloat
    var blurHash: BlurHash?
}

extension Photo {
    var aspectRatio: CGFloat {
        sizes.last.map { CGFloat($0.width) / CGFloat($0.height) } ?? 1
    }
}
