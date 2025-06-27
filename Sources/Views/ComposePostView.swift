import SwiftUI

struct ComposePostView: View {
    var titleKey: LocalizedStringKey
    @Binding var isShown: Bool

    @State private var text: String

    @FocusState private var isFocused: Bool

    init(_ titleKey: LocalizedStringKey, text: String = "", isShown: Binding<Bool>) {
        self.titleKey = titleKey
        self.text = text
        self._isShown = isShown
    }

    var body: some View {
        NavigationView {
            TextEditor(text: $text)
                .textInputAutocapitalization(.sentences)
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
                .focused($isFocused)
                .onAppear {
                    if #available(iOS 16, *) {
                        isFocused = true
                    } else {
                        // SwiftUI 💩
                        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(700)) {
                            isFocused = true
                        }
                    }
                }
        }
        .colorScheme(.light)
        .tint(nil)
    }
}

#Preview {
    ComposePostView("New Post", isShown: .constant(true))
}
