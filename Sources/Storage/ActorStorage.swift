import SmithereenAPI

@MainActor
final class ActorStorage {
    private var cache = LRUCache<UserID, UserProfileViewModel>(capacity: 1000)
}
