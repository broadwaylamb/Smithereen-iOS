import SwiftUI

struct UserProfileView: View {
    @ObservedObject var viewModel: UserProfileViewModel
    @StateObject var wallViewModel: WallViewModel

    @EnvironmentObject private var errorObserver: ErrorObserver

    private func refreshProfile() async {
        await errorObserver.runCatching {
            try await wallViewModel.reload()
        }
    }

    var body: some View {
        List {
            Section {
                UserProfileHeaderView(
                    profilePicture: viewModel.squareProfilePictureSizes,
                    fullName: viewModel.fullName,
                    onlineOrLastSeen: viewModel.onlineOrLastSeen,
                    ageAndPlace: viewModel.ageAndPlace,
                )
                .listRowInsets(
                    EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
                )

                let counters = [
                    ProfileCounter(value: viewModel.counters.friends) { "\($0) friends" },
                    ProfileCounter(value: viewModel.counters.mutualFriends) {
                        "\($0) in common"
                    },
                    ProfileCounter(value: viewModel.counters.followers) { "\($0) followers" },
                    ProfileCounter(value: viewModel.counters.groups) { "\($0) groups" },
                    ProfileCounter(value: viewModel.counters.photos) { "\($0) photos" },
                ]
                if counters.contains(where: { $0.value > 0 }) {
                    ProfileCountersView(counters: counters)
                        .listRowInsets(
                            EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0)
                        )
                }
            } header: {
                // Removing the top blank space
                // https://stackoverflow.com/a/78618856
                Spacer(minLength: 0)
                    .listRowInsets(EdgeInsets())
            }
            .listRowSeparatorLeadingInset(0)

            Section {
                WallSelectorView(
                    actor: viewModel.isMe
                        ? .me
                        : .user(
                            firstNameGenitive: viewModel.firstNameGenitive,
                            canSeeAllPosts: viewModel.canSeeAllPosts,
                        ),
                    selectedMode: $wallViewModel.wallMode,
                )
                .padding(.vertical, 8)
                .listRowInsets(
                    EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8)
                )
            } header: {
                Color.clear.frame(height: 19)
                    .listRowInsets(EdgeInsets())
            }
            ForEach(wallViewModel.filteredPosts) { postViewModel in
                Section {
                    CompactPostView(viewModel: postViewModel)
                        .listRowInsets(
                            EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4)
                        )
                        .listSectionSeparatorTint(Color(#colorLiteral(red: 0.7843137383, green: 0.7843137383, blue: 0.7843137383, alpha: 1)))
                }
            }
        }
        .task {
            await refreshProfile()
        }
        .refreshable {
            await refreshProfile()
        }
        .task(id: wallViewModel.wallMode) {
            await refreshProfile()
        }
        .listStyle(.grouped)
        .contentMarginsPolyfill(.top, 0)
        .listSectionSpacingPolyfill(0)
        .environment(\.defaultMinListHeaderHeight, 0)
        .colorScheme(.light)
        .navigationTitle(Text(verbatim: viewModel.firstName))
        .navigationBarStyleSmithereen()
    }
}

//#Preview {
//    NavigationView {
//        UserProfileView(
//            isMe: true,
//            viewModel: UserProfileViewModel(
//                user: User
//            )
//        )
//    }
//    .navigationViewStyle(.stack)
//    .navigationBarBackground(.visible)
//    .navigationBarColorScheme(.dark)
//    .environmentObject(PaletteHolder())
//    .environmentObject(ErrorObserver())
//}
