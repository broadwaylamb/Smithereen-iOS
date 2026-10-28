import SwiftUI

struct PostFooterView: View {
    var viewModel: PostViewModel

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject private var palette: PaletteHolder

    var body: some View {
        let metrics = PostViewMetrics(
            horizontalSizeClass: UIUserInterfaceSizeClass(horizontalSizeClass)
        )
        if horizontalSizeClass == .regular {
            VStack(spacing: 0) {
                palette.postFooterSeparator
                    .frame(width: .infinity, height: 1)
                    .padding(.leading, metrics.horizontalInset + 3)
                RegularPostFooterView(viewModel: viewModel)
                    .padding(.horizontal, metrics.horizontalInset)
            }
            .padding(.top, 15)
        } else {
            CompactPostFooterView(viewModel: viewModel)
                .padding(.horizontal, metrics.horizontalInset)
                .padding(.top, 13)
        }
    }
}
