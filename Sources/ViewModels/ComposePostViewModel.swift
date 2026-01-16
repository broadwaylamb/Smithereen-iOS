import SwiftUI
import SmithereenAPI

@MainActor
final class ComposePostViewModel: ObservableObject {
    private let errorObserver: ErrorObserver
    private let api: any APIService
    private let wallOwner: ActorID?
    private let repostedPost: PostViewModel?

    @Published var text: String = ""
    @Binding var isShown: Bool

    init(
        errorObserver: ErrorObserver,
        api: any APIService,
        wallOwner: ActorID?,
        isShown: Binding<Bool>,
        repostedPost: PostViewModel? = nil,
    ) {
        self.errorObserver = errorObserver
        self.api = api
        self.wallOwner = wallOwner
        self.repostedPost = repostedPost
        self._isShown = isShown
    }

    var showPlaceholder: Bool {
        text.isEmpty
    }

    var canSubmit: Bool {
        !text.isBlank || repostedPost != nil
    }

    private func done() {
        isShown = false
    }

    func submit() {
        Task {
            await errorObserver.runCatching {
                if let repostedPost {
                    _ = try await api.invokeMethod(
                        Wall.Repost(
                            postID: repostedPost.id,
                            message: text,
                            textFormat: .plain,
                            attachments: nil, // TODO: Support attachments
                            contentWarning: nil, // TODO: Support content warnings
                            guid: nil // FIXME: Pass GUID
                        )
                    )
                } else {
                    _ = try await api.invokeMethod(
                        Wall.Post(
                            ownerID: wallOwner, // TODO: Support posts on group walls
                            message: text,
                            textFormat: .plain,
                            attachments: nil, // TODO: Support attachments
                            contentWarning: nil, // TODO: Support content warnings
                            guid: nil, // FIXME: Pass GUID
                        )
                    )
                }
                // TODO: If this is a repost, update the repost count (#18)
                await done()
            }
        }
    }
}
