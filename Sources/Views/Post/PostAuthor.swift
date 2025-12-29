import SmithereenAPI
import Foundation

struct PostAuthor {
    var displayedName: String
    var profilePictureSizes: ImageSizes
}

extension PostAuthor {
    init(_ actor: Actor) {
        switch actor {
        case .user(let user):
            displayedName = user.nameComponents.formatted(.name(style: .medium))
            profilePictureSizes = user.squareProfilePictureSizes
        case .group(let group):
            displayedName = group.name
            profilePictureSizes = group.squareProfilePictureSizes
        }
    }
}
