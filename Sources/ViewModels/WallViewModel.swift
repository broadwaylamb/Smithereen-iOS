import SmithereenAPI
import SwiftUI

@MainActor
final class WallViewModel: ObservableObject {
    let api: any APIService
    let actorStorage: ActorStorage
    let ownerID: ActorID?

    @Published private var posts: [PostViewModel] = []

    @Published var wallMode: User.WallMode

    init(
        api: any APIService,
        actorStorage: ActorStorage,
        ownerID: ActorID?,
        wallMode: User.WallMode,
    ) {
        self.api = api
        self.actorStorage = actorStorage
        self.ownerID = ownerID
        self.wallMode = wallMode
    }

    func reload() async throws {
        let filter: Wall.Get.Filter
        switch wallMode {
        case .owner:
            filter = .owner
        case .all:
            filter = .all
        }
        let wall = try await api.invokeMethod(
            Execute.wallWithProfile(
                ownerID: ownerID,
                offset: nil, // TODO: Pagination
                count: nil, // TODO: Pagination
                filter: filter,
                fields: ActorStorage.actorFields,
            )
        )
        withAnimation(.easeIn) {
            let authors = actorStorage.cacheUsers(wall.profiles)
            posts = wall.map {
                PostViewModel(
                    api: api,
                    actorStorage: actorStorage,
                    authors: authors,
                    post: $0,
                )
            }
        }
    }

    var filteredPosts: [PostViewModel] {
        switch wallMode {
        case .owner:
            return posts.filter {
                $0.post.fromID == ownerID ?? ActorID(actorStorage.currentUserID)
            }
        case .all:
            return posts
        }
    }
}
