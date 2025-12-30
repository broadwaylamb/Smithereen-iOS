import SwiftUI
import SmithereenAPI

@MainActor
final class UserProfileViewModel: ObservableObject {
    private let api: any APIService
    private let userID: UserID?
    private let feedViewModel: FeedViewModel
    @Published var user: User?
    @Published private var posts: [PostViewModel] = []
    @Published var wallMode: WallMode = .allPosts

    init(
        api: any APIService,
        userID: UserID?,
        feedViewModel: FeedViewModel,
    ) {
        self.api = api
        self.userID = userID
        self.feedViewModel = feedViewModel
    }

    func updateAll() async throws {
        // TODO: Use Execute to simultaneously load posts and profile and everything
        // TODO: Specify fields
        let user = try await api.invokeMethod(Users.Get(fields: nil)).first
        let posts = try await api.invokeMethod(
            Wall.Get(
                ownerID: userID.map(ActorID.init),
                offset: nil, // TODO: Pagination
                count: nil, // TODO: Pagination
            )
        )
        withAnimation {
            self.user = user
            self.posts = posts.map {
                PostViewModel(api: api, post: $0, feed: feedViewModel)
            }
        }
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
                mutualFriends: 0,
                userPhotos: 0,
                followers: 0,
                subscriptions: 0,
            )
    }

    var onlineOrLastSeen: LocalizedStringKey? {
        guard let user else { return nil }
        if user.online == true {
            return "online"
        }
        if let lastSeen = user.lastSeen {
            return "last seen \(lastSeen.time, formatter: lastSeenDateFormatter)"
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

    var filteredPosts: [PostViewModel] {
        switch wallMode {
        case .allPosts:
            return posts
        case .ownPosts:
            return posts // TODO: Filter
        }
    }
}

private let lastSeenDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.doesRelativeDateFormatting = true
    formatter.dateStyle = .long
    formatter.timeStyle = .short
    return formatter
}()
