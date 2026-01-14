import SmithereenAPI
import SwiftUI

@MainActor
final class WallViewModel: ObservableObject {
    let api: any APIService
    let actorStorage: ActorStorage
    let ownerID: ActorID?

    @Published private var posts: [PostViewModel] = []

    init(api: any APIService, actorStorage: ActorStorage, ownerID: ActorID?) {
        self.api = api
        self.actorStorage = actorStorage
        self.ownerID = ownerID
    }

    func reload() async throws {
        let wall = try await api.invokeMethod(
            Execute.wallWithProfile(
                ownerID: ownerID,
                offset: nil, // TODO: Pagination
                count: nil, // TODO: Pagination
                filter: .all, // TODO: Use the correct filters
                fields: ActorStorage.actorFields,
            )
        )
        withAnimation(.easeIn) {
            let authors = actorStorage.cacheUsers(wall.profiles)
            posts = wall.items.map {
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
        return posts // TODO: Actually filter
    }
}
