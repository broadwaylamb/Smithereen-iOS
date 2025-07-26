import SwiftUI

@MainActor
private let impactFBG = UIImpactFeedbackGenerator()

@MainActor
private let notificationFBG = UINotificationFeedbackGenerator()

extension View {
    func likeButtonFeedback(liked: Bool) -> some View {
        if #available(iOS 17.0, *) {
            // NOTE: The condition here is inverted because SwiftUI.
            // We want .success when the user likes a post
            // and .impact when the user withdraws their like.
            // Counterintuitive as it is, this condition is correct.
            return sensoryFeedback(liked ? .impact : .success, trigger: liked)
        }
        return onChange(of: liked) { liked in
            if liked {
                notificationFBG.notificationOccurred(.success)
            } else {
                impactFBG.impactOccurred()
            }
        }
    }
}

