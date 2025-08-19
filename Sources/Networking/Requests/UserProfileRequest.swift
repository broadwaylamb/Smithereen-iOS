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
        let presense = try? body.select("div.profilePresence").first()?.text()

        let profilePictureURL = try? body
            .select("div.profileHeaderAva picture")
            .first()
            .flatMap(parsePicture)?
            .url

        return UserProfile(
            fullName: fullName,
            profilePicture: profilePictureURL.map(ImageLocation.remote),
            presence: presense,
        )
    }
}
