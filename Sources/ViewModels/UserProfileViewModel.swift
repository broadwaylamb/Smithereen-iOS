import SwiftUI

@MainActor
final class UserProfileViewModel: ObservableObject {
    private let api: any APIService
    private let userIDOrHandle: Either<UserID, String>?
    @Published var user: UserProfile?

    init(api: any APIService, userIDOrHandle: Either<UserID, String>?) {
        self.api = api
        self.userIDOrHandle = userIDOrHandle
    }

    func update() async throws {
        let request: UserProfileRequest
        switch userIDOrHandle {
        case .left(let userID)?:
            request = UserProfileRequest(userID: userID)
        case .right(let handle)?:
            request = UserProfileRequest(handle: handle)
        case nil:
            return
        }
        user = try await api.send(request)
    }
}
