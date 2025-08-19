struct UserProfile {
    var fullName: String
    var profilePicture: ImageLocation?
    var presence: String? // TODO: Replace with an enum when we drop HTML scraping
}
