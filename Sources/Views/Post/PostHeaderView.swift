import SwiftUI

struct PostHeaderView: View {
    var profilePicture: ImageLocation?
    var name: String
    var date: String

    @AppStorage(.palette) private var palette: Palette = .smithereen

    @ScaledMetric(relativeTo: .body)
    private var imageSize = 40

    @ViewBuilder
    private var profilePictureImage: some View {
        switch profilePicture {
        case .remote(let url):
            AsyncImage(
                url: url,
                scale: 2.0,
                content: { $0.resizable() },
                placeholder: { Color.gray },
            )
        case .bundled(let resource):
            Image(resource)
                .resizable()
        case nil:
            Color.red // TODO
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            profilePictureImage
                .frame(width: imageSize, height: imageSize)
                .cornerRadius(2.5)
            VStack(alignment: .leading, spacing: 7) {
                Text(name)
                    .bold()
                    .foregroundStyle(palette.accent)
                Text(date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button(action: { /* TODO */ }) {
                Image(systemName: "ellipsis").foregroundStyle(palette.ellipsis)
            }
        }
    }
}
