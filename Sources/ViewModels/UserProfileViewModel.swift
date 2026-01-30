import SwiftUI
import SmithereenAPI
import GRDB

@MainActor
final class UserProfileViewModel: ObservableObject {
    private let api: any APIService
    private let db: SmithereenDatabase
    let userID: UserID?

    @Published var user: User?

    private var observation: AnyDatabaseCancellable?

    /// `userID` being `nil` means the current user.
    init(api: any APIService, userID: UserID?, db: SmithereenDatabase) {
        self.api = api
        self.userID = userID
        self.db = db
        self.user = try? db.getUser(userID)

        let userIDForObservation = userID ?? db.currentUserID
        observation = db
            .observe(assignOn: self, \.user) { db in
                try User.fetchOne(db, id: userIDForObservation)
            }
    }

    var isMe: Bool {
        userID == nil
    }

    var fullName: String {
        user?.nameComponents.formatted(.name(style: .long)) ?? "…"
    }

    var firstName: String {
        user?.firstName ?? "…"
    }

    var firstNameGenitive: String {
        user?.firstNameGen ?? firstName
    }

    var canSeeAllPosts: Bool {
        user?.canSeeAllPosts ?? false
    }

    var counters: User.Counters {
        user?.counters
            ?? User.Counters(
                albums: 0,
                photos: 0,
                friends: 0,
                groups: 0,
                onlineFriends: 0,
                mutualFriends: user?.mutualCount ?? 0,
                userPhotos: 0,
                followers: user?.followersCount ?? 0,
                subscriptions: 0,
            )
    }

    var onlineOrLastSeen: LocalizedStringKey? {
        guard let user else { return nil }
        if user.online == true {
            return "online"
        }
        if let lastSeen = user.lastSeen {
            switch user.sex {
            case .male:
                return "last_seen_male \(lastSeen.time, formatter: AdaptiveDateFormatter.default)"
            case .female:
                return "last_seen_female \(lastSeen.time, formatter: AdaptiveDateFormatter.default)"
            case .other, nil:
                return "last_seen_other \(lastSeen.time, formatter: AdaptiveDateFormatter.default)"
            }
        }
        return nil
    }

    private var ageInYears: Int? {
        let now = Date()
        if let birthdayComponents = user?.birthday?.dateComponents,
           birthdayComponents.year != nil,
           let birthdayDate = birthdayComponents.date,
           birthdayDate < now
        {
            return Calendar
                .autoupdatingCurrent
                .dateComponents([.year], from: birthdayDate, to: now)
                .year
        }
        return nil
    }

    var ageAndPlace: LocalizedStringKey? {
        guard let user else { return nil }
        switch (ageInYears, user.city) {
        case (let age?, let city?):
            return "\(age) years old, \(city)"
        case (nil, let city?):
            return "\(city)"
        case (let age?, nil):
            return "\(age) years old"
        case (nil, nil):
            return nil
        }
    }

    var showMobileIcon: Bool {
        guard let user else { return false }
        return user.onlineMobile == true || user.lastSeen?.platform == .mobile
    }

    func createWallViewModel(db: SmithereenDatabase) -> WallViewModel {
        let wallMode: User.WallMode
        if let user, let wallDefault = user.wallDefault {
            wallMode = wallDefault
        } else {
            wallMode = canSeeAllPosts ? .all : .owner
        }
        return WallViewModel(
            api: api,
            db: db,
            ownerID: userID.map(ActorID.init),
            wallMode: wallMode,
        )
    }
}
