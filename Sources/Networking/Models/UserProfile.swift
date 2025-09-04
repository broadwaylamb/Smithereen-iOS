struct UserProfile {
    var fullName: String
    var profilePicture: ImageLocation?
    var presence: String? // TODO: Replace with an enum when we drop HTML scraping
    var friendCount: Int
    var commonFriendCount: Int
    var followerCount: Int
    var groupCount: Int
    var photoCount: Int = 0
    var videoCount: Int = 0
    var audioCount: Int = 0
}
