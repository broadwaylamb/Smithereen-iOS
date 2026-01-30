import SmithereenAPI
import SwiftUI

@MainActor
final class WallViewModel: ObservableObject {
    let api: any APIService
    let db: SmithereenDatabase
    let ownerID: ActorID?

    @Published private var posts: [PostViewModel] = []

    @Published var wallMode: User.WallMode

    init(
        api: any APIService,
        db: SmithereenDatabase,
        ownerID: ActorID?,
        wallMode: User.WallMode,
    ) {
        self.api = api
        self.db = db
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
        try db.cacheUsers(wall.profiles)
        withAnimation(.easeIn) {
            posts = wall.map {
                PostViewModel(
                    api: api,
                    db: db,
                    post: $0,
                    profiles: wall.profiles,
                )
            }
        }
    }

    var filteredPosts: [PostViewModel] {
        switch wallMode {
        case .owner:
            return posts.filter {
                $0.post.fromID == ownerID ?? ActorID(db.currentUserID)
            }
        case .all:
            return posts
        }
    }
}
