import SwiftUI

struct UserProfileView: View {
    var isMe: Bool
    var initialFirstName: String?
    var initialFullName: String
    @StateObject var viewModel: UserProfileViewModel

    @EnvironmentObject private var errorObserver: ErrorObserver

    private func refreshProfile() async {
        await errorObserver.runCatching {
            try await viewModel.update()
        }
    }

    private var firstName: String {
        viewModel.user?.fullName // TODO: User actual first name
            ?? initialFirstName
            ?? initialFullName
    }

    private var firstNameGenitive: String {
        firstName // TODO: Use actual first name in the genitive case
    }

    private var fullName: String {
        viewModel.user?.fullName ?? initialFullName
    }

    var body: some View {
        List {
            Section {
                UserProfileHeaderView(
                    profilePicture: viewModel.user?.profilePicture,
                    fullName: fullName,
                    onlineOrLastSeen: viewModel.user?.presence?.excludedFromLocalization,
                    ageAndPlace: nil, // TODO
                )
                .listRowInsets(
                    EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
                )

                let counters = [
                    ProfileCounter(value: viewModel.friendCount) { "\($0) friends" },
                    ProfileCounter(value: viewModel.commonFriendCount) {
                        "\($0) in common"
                    },
                    ProfileCounter(value: viewModel.followerCount) { "\($0) followers" },
                    ProfileCounter(value: viewModel.groupCount) { "\($0) groups" },
                    ProfileCounter(value: viewModel.photoCount) { "\($0) photos" },
                    ProfileCounter(value: viewModel.videoCount) { "\($0) videos" },
                    ProfileCounter(value: viewModel.audioCount) { "\($0) audios" },
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
                    actor: isMe
                        ? .me
                        : .user(
                            firstNameGenitive: firstNameGenitive,
                            isSmithereenUser: true // TODO
                        ),
                    mode: $viewModel.wallMode,
                )
                .padding(.vertical, 8)
                .listRowInsets(
                    EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8)
                )
            } header: {
                Color.clear.frame(height: 19)
                    .listRowInsets(EdgeInsets())
            }
            ForEach(viewModel.filteredPosts) { postViewModel in
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
        .listStyle(.grouped)
        .contentMarginsPolyfill(.top, 0)
        .listSectionSpacingPolyfill(0)
        .environment(\.defaultMinListHeaderHeight, 0)
        .colorScheme(.light)
        .navigationTitle(Text(verbatim: firstName))
        .navigationBarStyleSmithereen()
    }
}

#Preview {
    NavigationView {
        UserProfileView(
            isMe: true,
            initialFirstName: "Boromir",
            initialFullName: "Boromir",
            viewModel: UserProfileViewModel(
                api: MockApi(),
                userHandle: "boromir",
                feedViewModel: FeedViewModel(api: MockApi())
            )
        )
    }
    .navigationViewStyle(.stack)
    .navigationBarBackground(.visible)
    .navigationBarColorScheme(.dark)
    .environmentObject(PaletteHolder())
    .environmentObject(ErrorObserver())
}
