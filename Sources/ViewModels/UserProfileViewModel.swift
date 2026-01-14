import SwiftUI
import SmithereenAPI

@MainActor
final class UserProfileViewModel: ObservableObject {
    private let api: any APIService
    let userID: UserID?
    @Published var user: User?
    @Published var wallMode: User.WallMode

    /// `userID` being null means the current user.
    init(api: any APIService, userID: UserID?, user: User? = nil) {
        self.api = api
        self.userID = userID
        self.user = user
        self.wallMode = user?.wallDefault ?? .all
    }

    func loadProfile() async throws {
        user = try await api.invokeMethod(
            Users.Get(userIDs: userID.map { [$0] }, fields: ActorStorage.userFields)
        ).first
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

    var canPostOnWall: Bool {
        user?.canPost ?? false
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

    var squareProfilePictureSizes: ImageSizes {
        guard let user else { return .init() }
        var sizes = ImageSizes()
        sizes.append(size: 50, url: user.photo50)
        sizes.append(size: 100, url: user.photo100)
        sizes.append(size: 200, url: user.photo200)
        sizes.append(size: 400, url: user.photo400)
        sizes.append(size: .infinity, url: user.photoMax)
        return sizes
    }

    func toPostAuthor() -> PostAuthor {
        return PostAuthor(
            id: userID.map(ActorID.init),
            displayedName: user?.nameComponents.formatted(.name(style: .medium)) ?? "…",
            profilePictureSizes: squareProfilePictureSizes,
        )
    }

    func createWallViewModel(actorStorage: ActorStorage) -> WallViewModel {
        WallViewModel(
            api: api,
            actorStorage: actorStorage,
            ownerID: userID.map(ActorID.init)
        )
    }
}
