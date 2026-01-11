import SmithereenAPI

struct UserProfileNavigationItem: Hashable {
    /// If `nil`, navigate to the current user profile
    var userID: UserID?
}
