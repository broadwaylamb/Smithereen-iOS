import SwiftUI

enum WallMode {
    case allPosts
    case ownPosts
}

enum WallSelectorActor {
    case me
    case user(firstNameGenitive: String, isSmithereenUser: Bool)
    case group

    var buttonTitle: LocalizedStringKey? {
        switch self {
        case .me:
            return "My posts"
        case .user(firstNameGenitive: _, isSmithereenUser: false), .group:
            return nil
        case .user(let firstNameGenitive, isSmithereenUser: true):
            return "\(firstNameGenitive)'s posts"
        }
    }
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
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            WallSelectorButton(title: "All posts", mode: .allPosts, selectedMode: $mode)
            if let title = actor.buttonTitle {
                WallSelectorButton(title: title, mode: .ownPosts, selectedMode: $mode)
            }
        }
        .lineLimit(1)
        .tint(palette.profileCounterNumber)
    }
}

@available(iOS 17.0, *)
#Preview {
    @Previewable @State var mode = WallMode.allPosts
    WallSelectorView(actor: .me, mode: $mode)
        .environmentObject(PaletteHolder())
}
