import SwiftUI

struct ComposePostView: View {
    var titleKey: LocalizedStringKey
    var placeholder: LocalizedStringKey

    @ObservedObject private var viewModel: ComposePostViewModel

    init(
        _ titleKey: LocalizedStringKey,
        placeholder: LocalizedStringKey,
        viewModel: ComposePostViewModel,
    ) {
        self.titleKey = titleKey
        self.placeholder = placeholder
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationView {
            ComposePostAdapter(text: $viewModel.text)
                .overlay(alignment: .topLeading) {
                    if viewModel.showPlaceholder {
                        Text(placeholder)
                            .font(.body)
                            .foregroundStyle(Color(UIColor.placeholderText))
                            // The same padding as UITextView uses for its text content.
                            .padding(8)
                            .allowsHitTesting(false)
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .navigationTitle(titleKey)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel", role: .cancel) {
                            viewModel.isShown = false
                        }
                        .buttonStyle(.borderless)
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: viewModel.submit) {
                            Text("Done").bold()
                        }
                        .disabled(!viewModel.canSubmit)
                        .buttonStyle(.borderless)
                    }
                    ToolbarItem(placement: .keyboard) {
                        // TODO: Attachments
                    }
                }
        }
        .colorScheme(.light)
        .tint(nil)
    }
}

extension ComposePostView {
    static func forRepost(
        isShown: Binding<Bool>,
        errorObserver: ErrorObserver,
        repostedPostViewModel: PostViewModel
    ) -> ComposePostView {
        ComposePostView(
            "compose_repost_title",
            placeholder: "Add your comment",
            viewModel: repostedPostViewModel
                .createComposeRepostViewModel(
                    isShown: isShown,
                    errorObserver: errorObserver
                )
        )
    }
}

/// Unlike SwiftUI's `TextEditor`, `UITextView` supports
/// showing the keyboard upon presenting without delay.
private struct ComposePostAdapter: UIViewRepresentable {
    @Binding var text: String

    @State private var isFocused = true

    class Coordinator: NSObject, UITextViewDelegate {
        @Binding var isFocused: Bool
        @Binding var text: String

        init(isFocused: Binding<Bool>, text: Binding<String>) {
            self._isFocused = isFocused
            self._text = text
        }

        func textViewDidChange(_ textView: UITextView) {
            text = textView.text ?? ""
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            isFocused = true
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            isFocused = false
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(isFocused: $isFocused, text: $text)
    }

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.delegate = context.coordinator
        view.text = text
        view.autocapitalizationType = .sentences
        view.adjustsFontForContentSizeCategory = true
        view.font = .preferredFont(forTextStyle: .body)
        view.textContainerInset = UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 4)

        return view
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        // https://stackoverflow.com/a/63142687
        DispatchQueue.main.async {
            if isFocused {
                uiView.becomeFirstResponder()
            } else {
                uiView.resignFirstResponder()
            }
        }

        uiView.font = .preferredFont(
            forTextStyle: .body,
            compatibleWith: UITraitCollection(
                preferredContentSizeCategory: UIContentSizeCategory(
                    context.environment.dynamicTypeSize
                )
            )
        )
    }
}

#Preview {
    ComposePostView(
        "New Post",
        placeholder: "What's new?",
        viewModel: ComposePostViewModel(
            errorObserver: ErrorObserver(),
            api: MockApi(),
            userID: UserID(rawValue: 1),
            isShown: .constant(true),
            showNewPost: { _ in },
        )
    )
}
