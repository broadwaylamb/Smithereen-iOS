import SwiftUI

struct UserProfileView: View {
    var firstName: String
    @StateObject var viewModel: UserProfileViewModel

    @EnvironmentObject private var errorObserver: ErrorObserver

    private func refreshProfile() async {
        await errorObserver.runCatching {
            try await viewModel.update()
        }
    }

    var body: some View {
        List {
            if let user = viewModel.user {
                Section {
                    UserProfileHeaderView(
                        profilePicture: user.profilePicture,
                        fullName: user.fullName,
                        onlineOrLastSeen: user.presence?.excludedFromLocalization,
                        ageAndPlace: nil, // TODO
                    )
                    .listRowInsets(
                        EdgeInsets(top: 9, leading: 9, bottom: 9, trailing: 9)
                    )
                }
            }
        }
        .task {
            await refreshProfile()
        }
        .refreshable {
            await refreshProfile()
        }
        .listStyle(.grouped)
        .contentMarginsPolyfill(.top, 0)
        .colorScheme(.light)
        .navigationTitle(Text(verbatim: firstName))
        .navigationBarStyleSmithereen()
    }
}

#Preview {
    NavigationView {
        UserProfileView(
            firstName: "Boromir",
            viewModel: UserProfileViewModel(
                api: MockApi(),
                userIDOrHandle: .left(UserID(rawValue: 1)),
            )
        )
    }
    .navigationViewStyle(.stack)
    .navigationBarBackground(.visible)
    .navigationBarColorScheme(.dark)
    .environmentObject(PaletteHolder())
    .environmentObject(ErrorObserver())
}
