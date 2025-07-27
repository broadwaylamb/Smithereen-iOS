import SwiftUI

@MainActor
final class ComposePostViewModel: ObservableObject {
    private let errorObserver: ErrorObserver
    private let api: any APIService
    private let userID: UserID?
    private let showNewPost: @MainActor (Post) -> Void

    @Published private(set) var showActivityIndicator: Bool = false
    @Published var text: String = ""
    @Binding var isShown: Bool

    init(
        errorObserver: ErrorObserver,
        api: any APIService,
        userID: UserID?,
        isShown: Binding<Bool>,
        showNewPost: @MainActor @escaping (Post) -> Void,
    ) {
        self.errorObserver = errorObserver
        self.api = api
        self.userID = userID
        self.showNewPost = showNewPost
        self._isShown = isShown
    }

    var showPlaceholder: Bool {
        text.isEmpty
    }

    var canSubmit: Bool {
        !text.isEmpty && userID != nil
    }

    private func setActivityIndicator(_ value: Bool) {
        showActivityIndicator = value
    }

    private func done(_ newPost: Post?) {
        isShown = false
        setActivityIndicator(false)
        if let newPost {
            showNewPost(newPost)
        }
    }

    func submit() {
        guard let userID = userID else { return }

        setActivityIndicator(true)
        Task {
            await errorObserver.runCatching {
                let response: CreateWallPostResponse
                do {
                     response = try await api
                        .send(CreateWallPostRequest(text: text, userID: userID))
                } catch {
                    await setActivityIndicator(false)
                    throw error
                }
                await done(response.newPost)
            }
        }
    }
}
