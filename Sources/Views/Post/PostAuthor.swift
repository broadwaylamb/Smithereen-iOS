import SmithereenAPI
import Foundation

struct PostAuthor {
    var id: ActorID
    var displayedName: String
    var profilePictureSizes: ImageSizes
}

extension PostAuthor {
    init(_ actor: Actor) {
        switch actor {
        case .user(let user):
            id = ActorID(user.id)
            displayedName = user.nameComponents.formatted(.name(style: .medium))
            profilePictureSizes = user.squareProfilePictureSizes
        case .group(let group):
            id = ActorID(group.id)
            displayedName = group.name
            profilePictureSizes = group.squareProfilePictureSizes
        }
    }
}
