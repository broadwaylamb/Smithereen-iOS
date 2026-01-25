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

    private func done(repostResult: RepostWithCounters? = nil) {
        isShown = false
        if let repostedPost, let repostResult {
            repostedPost.reposted = true
            repostedPost.repostCount = repostResult.repostsCount
            repostedPost.likeCount = repostResult.repostsCount
        }
    }

    func submit() {
        Task {
            await errorObserver.runCatching {
                if let repostedPost {
                    let result = try await api.invokeMethod(
                        Execute.repostWithCounters(
                            postID: repostedPost.id,
                            message: text,
                            textFormat: .plain,
                            attachments: nil, // TODO: Support attachments
                            contentWarning: nil, // TODO: Support content warnings
                            guid: nil // FIXME: Pass GUID
                        )
                    )
                    await done(repostResult: result)
                } else {
                    _ = try await api.invokeMethod(
                        Wall.Post(
                            ownerID: wallOwner,
                            message: text,
                            textFormat: .plain,
                            attachments: nil, // TODO: Support attachments
                            contentWarning: nil, // TODO: Support content warnings
                            guid: nil, // FIXME: Pass GUID
                        )
                    )
                    await done()
                }
            }
        }
    }
}
