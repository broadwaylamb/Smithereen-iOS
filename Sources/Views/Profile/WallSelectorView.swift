import Placement
import SwiftUI

enum WallMode {
    case allPosts
    case ownPosts
}

enum WallSelectorActor {
    case me
    case user(firstNameGenitive: String, canPost: Bool)
    case group
}

private struct WallSelectorButton: View {
    var title: LocalizedStringKey
    var mode: WallMode
    @Binding var selectedMode: WallMode
    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.1)) {
                selectedMode = mode
            }
        } label: {
            Text(title)
                .font(.callout)
                .fontWeight(.semibold)
        }
        .buttonStyle(.borderless)
        .padding(.horizontal, 11)
        .padding(.vertical, 6)
    }
}

struct WallSelectorView: View {
    var actor: WallSelectorActor
    @Binding var selectedMode: WallMode
    @EnvironmentObject private var palette: PaletteHolder
    @Namespace private var animationNamespace

    @ViewBuilder
    private func selectorBackground(mode: WallMode) -> some View {
        if selectedMode == mode {
            Color(#colorLiteral(red: 0.8902018666, green: 0.8901113868, blue: 0.8988136053, alpha: 1))
                .cornerRadius(3)
                .matchedGeometryEffect(
                    id: "selectorBackground",
                    in: animationNamespace,
                )
        }
    }

    private func button(_ title: LocalizedStringKey, mode: WallMode) -> some View {
        WallSelectorButton(title: title, mode: mode, selectedMode: $selectedMode)
            .background {
                selectorBackground(mode: mode)
            }
    }

    private func buttonThatFits(
        longTitle: LocalizedStringKey,
        shortTitle: LocalizedStringKey,
        mode: WallMode,
    ) -> some View {
        PlacementThatFits(in: .horizontal, prefersViewThatFits: false) {
            WallSelectorButton(title: longTitle, mode: mode, selectedMode: $selectedMode)
            WallSelectorButton(title: shortTitle, mode: mode, selectedMode: $selectedMode)
        }
        .background {
            selectorBackground(mode: mode)
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            switch actor {
            case .me:
                button("All posts", mode: .allPosts)
                button("My posts", mode: .ownPosts)
            case .user(let firstNameGenitive, canPost: true):
                button("All posts", mode: .allPosts)
                buttonThatFits(
                    longTitle: "\(firstNameGenitive)'s posts",
                    shortTitle: "Own posts",
                    mode: .ownPosts
                )
            case .user(let firstNameGenitive, canPost: false):
                buttonThatFits(
                    longTitle: "\(firstNameGenitive)'s posts",
                    shortTitle: "All posts",
                    mode: .allPosts
                )
            case .group:
                button("All posts", mode: .allPosts)
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
        actor: .user(firstNameGenitive: "Boromir", canPost: true),
        selectedMode: $mode,
    )
    .environmentObject(PaletteHolder())
}
