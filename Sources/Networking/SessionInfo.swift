import SmithereenAPI

struct SessionInfo: Hashable, Codable, Sendable {
    var host: String
    var port: Int?
    var accessToken: AccessToken
    var userID: UserID
}
