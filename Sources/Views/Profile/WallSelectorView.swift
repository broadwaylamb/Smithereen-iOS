import Placement
import SwiftUI

enum WallMode {
    case allPosts
    case ownPosts
}

enum WallSelectorActor {
    case me
    case user(firstNameGenitive: String, supportsWalls: Bool)
    case group
}

private struct WallSelectorButton: View {
    var title: LocalizedStringKey
    var mode: WallMode
    @Binding var selectedMode: WallMode
    var body: some View {
        Button {
            selectedMode = mode
        } label: {
            Text(title)
                .font(.callout)
                .fontWeight(.semibold)
        }
        .buttonStyle(.borderless)
        .padding(.horizontal, 11)
        .padding(.vertical, 6)
        .background {
            if selectedMode == mode {
                Color(#colorLiteral(red: 0.8902018666, green: 0.8901113868, blue: 0.8988136053, alpha: 1))
                    .cornerRadius(3)
            }
        }
    }
}

struct WallSelectorView: View {
    var actor: WallSelectorActor
    @Binding var mode: WallMode
    @EnvironmentObject private var palette: PaletteHolder

    var body: some View {
        HStack(spacing: 12) {
            switch actor {
            case .me:
                WallSelectorButton(
                    title: "All posts",
                    mode: .allPosts,
                    selectedMode: $mode,
                )
                WallSelectorButton(
                    title: "My posts",
                    mode: .ownPosts,
                    selectedMode: $mode,
                )
            case .user(let firstNameGenitive, supportsWalls: true):
                WallSelectorButton(
                    title: "All posts",
                    mode: .allPosts,
                    selectedMode: $mode,
                )
                PlacementThatFits(in: .horizontal) {
                    // If the name is too long and doesn't fit, don't truncate it,
                    // don't use the name at all instead.
                    WallSelectorButton(
                        title: "\(firstNameGenitive)'s posts",
                        mode: .ownPosts,
                        selectedMode: $mode,
                    )
                    WallSelectorButton(
                        title: "Own posts",
                        mode: .ownPosts,
                        selectedMode: $mode
                    )
                }
            case .user(let firstNameGenitive, supportsWalls: false):
                PlacementThatFits(in: .horizontal) {
                    // If the name is too long and doesn't fit, don't truncate it,
                    // don't use the name at all instead.
                    WallSelectorButton(
                        title: "\(firstNameGenitive)'s posts",
                        mode: .allPosts,
                        selectedMode: $mode,
                    )
                    WallSelectorButton(
                        title: "All posts",
                        mode: .allPosts,
                        selectedMode: $mode
                    )
                }
            case .group:
                WallSelectorButton(
                    title: "All posts",
                    mode: .allPosts,
                    selectedMode: $mode,
                )
            }
        }
        .lineLimit(1)
        .tint(palette.profileCounterNumber)
    }
}

@available(iOS 17.0, *)
#Preview(traits: .sizeThatFitsLayout) {
    @Previewable @State var mode = WallMode.allPosts
    WallSelectorView(
        actor: .user(firstNameGenitive: "Boromir", supportsWalls: true),
        mode: $mode,
    )
    .environmentObject(PaletteHolder())
}
