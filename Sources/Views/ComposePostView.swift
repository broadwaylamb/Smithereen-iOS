import SwiftUI

struct ComposePostView: View {
    var titleKey: LocalizedStringKey
    var placeholder: LocalizedStringKey
    @Binding var isShown: Bool

    @State private var text: String

    @State private var isFocused: Bool = true

    init(
        _ titleKey: LocalizedStringKey,
        placeholder: LocalizedStringKey,
        text: String = "",
        isShown: Binding<Bool>
    ) {
        self.titleKey = titleKey
        self.placeholder = placeholder
        self.text = text
        self._isShown = isShown
    }

    var body: some View {
        NavigationView {
            ComposePostAdapter(isFocused: $isFocused, text: $text)
                .overlay(alignment: .topLeading) {
                    if text.isEmpty {
                        Text(placeholder)
                            .font(.body)
                            .foregroundStyle(Color(UIColor.placeholderText))
                            // The same padding as UITextView uses for its text content.
                            .padding(8)
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .navigationTitle(titleKey)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel", role: .cancel) {
                            isShown = false
                        }
                        .buttonStyle(.borderless)
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            // TODO: Submit the post
                        } label: {
                            Text("Done").bold()
                        }
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

/// Unlike SwiftUI's `TextEditor`, `UITextView` supports
/// showing the keyboard upon presenting without delay.
private struct ComposePostAdapter: UIViewRepresentable {
    @Binding var isFocused: Bool
    @Binding var text: String

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
        if isFocused {
            uiView.becomeFirstResponder()
        } else {
            uiView.resignFirstResponder()
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
        isShown: .constant(true),
    )
}
