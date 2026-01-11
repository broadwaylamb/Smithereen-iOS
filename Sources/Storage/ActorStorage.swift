import SmithereenAPI

@MainActor
final class ActorStorage {
    private unowned let api: any APIService

    let currentUserID: UserID
    let currentUserViewModel: UserProfileViewModel
    private var userCache = LRUCache<UserID, UserProfileViewModel>(capacity: 1000)

    init(api: any APIService, currentUserID: UserID) {
        self.api = api
        self.currentUserID = currentUserID
        self.currentUserViewModel = UserProfileViewModel(api: api, userID: nil)
    }

    static let userFields: [User.Field] = [
        .status,
        .url,
        .nickname,
        .maidenName,
        .sex,
        .birthday,
        .homeTown,
        .relation,
        .customProfileFields,
        .city,
        .connections,
        .site,
        .activities,
        .interests,
        .music,
        .movies,
        .tv,
        .books,
        .games,
        .quotes,
        .about,
        .personal,
        .online,
        .lastSeen,
        .blockedByMe,
        .canPost,
        .canSeeAllPosts,
        .canSendFriendRequest,
        .canWritePrivateMessage,
        .mutualCount,
        .friendStatus,
        .isFriend,
        .isHiddenFromFeed,
        .followersCount,
        .wallDefault,
        .photo50,
        .photo100,
        .photo200,
        .photo400,
        .photoMax,
        .photo200Orig,
        .photo400Orig,
        .photoMaxOrig,
        .photoID,
        .hasPhoto,
        .cropPhoto,
        .firstNameGen,
        .counters,
    ]

    static let groupFields: [Group.Field] = [
    ]

    static let actorFields: [ActorField] =
        (userFields.map(ActorField.init) + groupFields.map(ActorField.init)).distinct()

    func cacheUser(_ user: User) -> UserProfileViewModel {
        if user.id == currentUserViewModel.userID {
            currentUserViewModel.user = user
            return currentUserViewModel
        }
        if let existingViewModel = userCache[user.id] {
            existingViewModel.user = user
            return existingViewModel
        }

        let newViewModel = UserProfileViewModel(api: api, userID: user.id, user: user)
        userCache[user.id] = newViewModel
        return newViewModel
    }

    func cacheUsers<Users: Sequence<User>>(
        _ users: Users
    ) -> [UserID : UserProfileViewModel] {
        var result = [UserID : UserProfileViewModel]()
        for user in users {
            result[user.id] = cacheUser(user)
        }
        return result
    }

    private func fetch(
        userID: UserID?,
        into viewModel: UserProfileViewModel,
    ) async throws {
        let users = try await api.invokeMethod(
            Users.Get(
                userIDs: userID.map { [$0] },
                fields: Self.userFields,
                relationCase: .default
            )
        )

        guard let user = users.first else {
            throw DecodingError.valueNotFound(
                User.self,
                DecodingError.Context(codingPath: [], debugDescription: "Empty user list")
            )
        }

        viewModel.user = user
    }

    func isCurrentUser(_ userID: UserID) -> Bool {
        currentUserID == userID
    }

    func getUser(_ userID: UserID?) -> UserProfileViewModel {
        guard let userID else {
            return currentUserViewModel
        }
        if isCurrentUser(userID) {
            return currentUserViewModel
        }
        return userCache[userID, default: UserProfileViewModel(api: api, userID: userID)]
    }
}
