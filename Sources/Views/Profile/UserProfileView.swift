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
                        EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
                    )

                    let counters = [
                        ProfileCounter(value: user.friendCount) { "\($0) friends" },
                        ProfileCounter(value: user.commonFriendCount) {
                            "\($0) in common"
                        },
                        ProfileCounter(value: user.followerCount) { "\($0) followers" },
                        ProfileCounter(value: user.groupCount) { "\($0) groups" },
                        ProfileCounter(value: user.photoCount) { "\($0) photos" },
                        ProfileCounter(value: user.videoCount) { "\($0) videos" },
                        ProfileCounter(value: user.audioCount) { "\($0) audios" },
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
