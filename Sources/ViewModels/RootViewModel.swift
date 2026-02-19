import GRDB
import SmithereenAPI
import SwiftUI

@MainActor
final class RootViewModel: ObservableObject {
    let api: any APIService
    let db: SmithereenDatabase
    let feedViewModel: FeedViewModel

    @Published private var currentUser: User?

    // periphery:ignore
    private var currentUserObservation: AnyDatabaseCancellable?

    init(api: any APIService, db: SmithereenDatabase) {
        self.api = api
        self.db = db
        self.feedViewModel = FeedViewModel(api: api, db: db)
        currentUser = try? db.getUser(nil)
        let currentUserID = db.currentUserID
        currentUserObservation = db
            .observe(assignOn: self, \.currentUser) { db in
                try User.fetchOne(db, id: currentUserID)
            }
    }

    func load() async throws {
        let request = Users.Get(userIDs: nil, fields: ActorStorage.userFields)
        let user = try await api.invokeMethod(request)
        try db.cacheUsers(user)
    }

    var profileRowTitle: String {
        currentUser?.firstName ?? String(localized: "Profile")
    }

    var profilePictureSizes: ImageSizes? {
        currentUser?.squareProfilePictureSizes
    }
}

