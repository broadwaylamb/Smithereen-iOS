import Hammond
import SwiftSoup

struct UserProfileRequest: DecodableRequestProtocol {
    let path: String

    init(handle: String) {
        path = "/\(handle)"
    }

    init(userID: UserID) {
        path = "/users/\(userID)"
    }

    static var method: HTTPMethod { .get }

    static func deserializeResult(from body: Document) throws -> UserProfile {
        let fullName = try body.select("div.profileName").text()
        let presence = try? body.select("div.profilePresence").first()?.text()

        let profilePictureURL = try? body
            .select("div.profileHeaderAva picture")
            .first()
            .flatMap(parsePicture)?
            .url

        let friendCounters = try? body.select(".iconFriends + span.text b")
        let followersCounter = try? body.select(".iconFollowers + span.text b").first()

        let groupCounter = try? body
            .select(".profileSectionThumbs a[href$=\"/groups\"] .count")
            .first()

        return UserProfile(
            fullName: fullName,
            profilePicture: profilePictureURL.map(ImageLocation.remote),
            presence: presence,
            friendCount: (try? friendCounters?[safe: 0]?.text().parseInt()) ?? 0,
            commonFriendCount: (try? friendCounters?[safe: 1]?.text().parseInt()) ?? 0,
            followerCount: (try? followersCounter?.text().parseInt()) ?? 0,
            groupCount: (try? groupCounter?.text().parseInt()) ?? 0,
        )
    }
}
