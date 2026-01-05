import SwiftUI

/// Regular `SwiftUI.Text` embedded in a `ScrollView` is REALLY
/// slow for large text amounts, so we use a `UITextView` for that.
struct TechnicalDataTextView: UIViewRepresentable {
    var content: String

    init(_ content: String) {
        self.content = content
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.font = UIFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        textView.text = content
    }
}

