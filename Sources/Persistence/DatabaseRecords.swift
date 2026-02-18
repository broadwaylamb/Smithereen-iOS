import Foundation
import GRDB
import SmithereenAPI
import SmithereenAPIInternals

protocol APIEntityDatabaseRecord: PersistableRecord, FetchableRecord {

    associatedtype DatabaseEntity: Codable

    /// Leave only the fields that exist as columns in the corresponding database table
    func prepareForDatabase() -> DatabaseEntity

    static func fromDatabaseEntity(_ entity: DatabaseEntity) -> Self
}

private struct DecodingAdapter<T: Decodable>: Decodable, FetchableRecord {
    var wrappedValue: T
    init(from decoder: any Decoder) throws {
        self.wrappedValue = try T(from: decoder)
    }
}

extension APIEntityDatabaseRecord {
    public func encode(to container: inout PersistenceContainer) throws {
        try encodeNonNilFields(of: prepareForDatabase(), into: &container)
    }

    public init(row: Row) throws {
        self = Self.fromDatabaseEntity(try DecodingAdapter(row: row).wrappedValue)
    }
}

extension APIEntityDatabaseRecord where DatabaseEntity == Self {
    static func fromDatabaseEntity(_ entity: DatabaseEntity) -> Self {
        return entity
    }
}

extension User: @retroactive PersistableRecord, @retroactive FetchableRecord {}

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

extension ActorID {
    fileprivate init(userID: UserID?, groupID: GroupID?) {
        if let userID {
            self.init(userID)
        } else if let groupID {
            self.init(groupID)
        } else {
            preconditionFailure("Could not initialize ActorID")
        }
    }
}

struct WallPostForDatabase: Codable {
    var id: WallPostID
    var userOwnerId: UserID?
    var groupOwnerId: GroupID?
    var fromUserId: UserID?
    var fromGroupId: GroupID?
    @URLAsString var apId: URL
    @URLAsString var url: URL
    @UnixTimestamp var date: Date
    var text: String?
    var likes: LikeInfo?
    var attachments: [Attachment]?
    var contentWarning: String?
    var canDelete: Bool
    var canEdit: Bool
    var privacy: WallPost.Privacy?
    var postSource: WallPost.Source?
    var comments: WallPost.Comments?
    var canPin: Bool?
    var isPinned: Bool?
}

extension WallPost: @retroactive PersistableRecord, @retroactive FetchableRecord {}

struct RepostDatabaseRecord: Codable, FetchableRecord, PersistableRecord {
    var repostId: WallPostID
    var repostedId: WallPostID
    var isMastodonStyle: Bool

    static var databaseTableName: String { "repost" }

    enum Columns {
        static let repostID = Column("repost_id")
        static let repostedID = Column("reposted_id")
    }

    static let repostIDForeignKey = ForeignKey([Columns.repostID])
    static let repostedIDForeignKey = ForeignKey([Columns.repostedID])

    static let reposted = belongsTo(WallPost.self, using: repostedIDForeignKey)

    static var databaseColumnDecodingStrategy: DatabaseColumnDecodingStrategy {
        .convertFromSnakeCase
    }

    static var databaseColumnEncodingStrategy: DatabaseColumnEncodingStrategy {
        .convertToSnakeCase
    }
}

extension WallPost: APIEntityDatabaseRecord {
    enum Columns {
        static let userOwnerID = Column("user_owner_id")
    }

    static let reposted = hasMany(
        RepostDatabaseRecord.self,
        key: "repost",
        using: RepostDatabaseRecord.repostIDForeignKey,
    )

    static let repostHistoryAssociation = hasMany(
        WallPost.self,
        through: WallPost.reposted,
        using: RepostDatabaseRecord.reposted,
        key: "repost",
    )

    public static var databaseColumnDecodingStrategy: DatabaseColumnDecodingStrategy {
        .convertFromSnakeCase
    }

    public static var databaseColumnEncodingStrategy: DatabaseColumnEncodingStrategy {
        .convertToSnakeCase
    }

    func prepareForDatabase() -> WallPostForDatabase {
        WallPostForDatabase(
            id: id,
            userOwnerId: ownerID.userID,
            groupOwnerId: ownerID.groupID,
            fromUserId: fromID.userID,
            fromGroupId: fromID.groupID,
            apId: activityPubID,
            url: url,
            date: date,
            text: text,
            likes: likes,
            attachments: attachments,
            contentWarning: contentWarning,
            canDelete: canDelete,
            canEdit: canEdit,
            privacy: privacy,
            postSource: postSource,
            comments: comments,
            canPin: canPin,
            isPinned: isPinned,
        )
    }

    static func fromDatabaseEntity(_ entity: WallPostForDatabase) -> WallPost {
        WallPost(
            id: entity.id,
            ownerID: ActorID(userID: entity.userOwnerId, groupID: entity.groupOwnerId),
            fromID: ActorID(userID: entity.fromUserId, groupID: entity.fromGroupId),
            activityPubID: entity.apId,
            url: entity.url,
            date: entity.date,
            text: entity.text,
            likes: entity.likes,
            attachments: entity.attachments,
            contentWarning: entity.contentWarning,
            canDelete: entity.canDelete,
            canEdit: entity.canEdit,
            privacy: entity.privacy,
            postSource: entity.postSource,
            comments: entity.comments,
            canPin: entity.canPin,
            isPinned: entity.isPinned,
        )
    }
}

extension WallPostID: @retroactive DatabaseValueConvertible {}
extension GroupID: @retroactive DatabaseValueConvertible {}
