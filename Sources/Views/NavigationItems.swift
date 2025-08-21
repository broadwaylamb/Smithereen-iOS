struct UserProfileNavigationItem: Hashable {
    var firstName: String
    var userIDOrHandle: Either<UserID, String>
}
