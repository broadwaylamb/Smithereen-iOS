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

struct WallSelectorView: View {
    var actor: WallSelectorActor
    @Binding var mode: WallMode
    @EnvironmentObject private var palette: PaletteHolder

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Button("All posts") {
                mode = .allPosts
            }
            if let buttonTitle = actor.buttonTitle {
                Button(buttonTitle) {
                    mode = .ownPosts
                }
            }
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.roundedRectangle)
        .font(.callout)
        .listRowInsets(EdgeInsets(top: 7, leading: 7, bottom: 7, trailing: 7))
        .tint(palette.profileCounterNumber)
    }
}

@available(iOS 17.0, *)
#Preview {
    @Previewable @State var mode = WallMode.allPosts
    WallSelectorView(actor: .me, mode: $mode)
}
