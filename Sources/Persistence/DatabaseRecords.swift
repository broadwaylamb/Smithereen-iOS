import GRDB
import SmithereenAPI

protocol APIEntityDatabaseRecord: Codable, PersistableRecord, FetchableRecord {

    /// Leave only the fields that exist as columns in the corresponding database table
    func prepareForDatabase() -> Self
}

extension APIEntityDatabaseRecord {
    public func encode(to container: inout PersistenceContainer) throws {
        try encodeNonNilFields(of: prepareForDatabase(), into: &container)
    }
}

extension User: @retroactive PersistableRecord {}
extension User: @retroactive FetchableRecord {}

extension User: APIEntityDatabaseRecord {
    public enum Columns {
        // Basic fields
        static let id = Column("id")
    }

    func prepareForDatabase() -> User {
        User(
            id: id,
            firstName: firstName,
            lastName: lastName,
            deactivated: deactivated,
            activityPubID: activityPubID,
            domain: domain,
            status: status,
            url: url,
            nickname: nickname,
            maidenName: maidenName,
            sex: sex,
            birthday: birthday,
            homeTown: homeTown,
            relation: relation,
            relationPartner: relationPartner,
            customProfileFields: customProfileFields,
            city: city,
            connections: connections,
            site: site,
            activities: activities,
            interests: interests,
            music: music,
            movies: movies,
            tv: tv,
            books: books,
            games: games,
            quotes: quotes,
            about: about,
            personal: personal,
            lastSeen: lastSeen,
            blocked: blocked,
            blockedByMe: blockedByMe,
            canPost: canPost,
            canSeeAllPosts: canSeeAllPosts,
            canSendFriendRequest: canSendFriendRequest,
            canWritePrivateMessage: canWritePrivateMessage,
            friendStatus: friendStatus,
            isFriend: isFriend,
            isFavorite: isFavorite,
            isHiddenFromFeed: isHiddenFromFeed,
            wallDefault: wallDefault,
            photo50: photo50,
            photo100: photo100,
            photo200: photo200,
            photo400: photo400,
            photoMax: photoMax,
            photo200Orig: photo200Orig,
            photo400Orig: photo400Orig,
            photoMaxOrig: photoMaxOrig,
            photoID: photoID,
            hasPhoto: hasPhoto,
            firstNameGen: firstNameGen,
            counters: counters,
        )
    }
}

extension UserID: @retroactive DatabaseValueConvertible {}

