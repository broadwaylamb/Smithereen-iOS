import SmithereenAPI

enum ActorStorage {
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
        .blocked,
        .blockedByMe,
        .canPost,
        .canSeeAllPosts,
        .canSendFriendRequest,
        .canWritePrivateMessage,
        .mutualCount,
        .friendStatus,
        .isFriend,
        .isFavorite,
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
        .firstNameGen,
        .counters,
    ]

    static let groupFields: [Group.Field] = [
    ]

    static let actorFields: [ActorField] =
        (userFields.map(ActorField.init) + groupFields.map(ActorField.init)).distinct()
}
