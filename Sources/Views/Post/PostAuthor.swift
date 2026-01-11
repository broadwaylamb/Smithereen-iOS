import SmithereenAPI
import Foundation

struct PostAuthor {
    /// If `nil`, this is the post from the current user.
    var id: ActorID?
    var displayedName: String
    var profilePictureSizes: ImageSizes
}
