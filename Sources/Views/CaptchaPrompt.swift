import CustomAlert
import SwiftUI
import SmithereenAPI

private struct CaptchaPromptViewModifier: ViewModifier {
    @Binding var captchaPrompt: CaptchaPrompt?

    @State private var answer: String = ""

    @Environment(\.displayScale) private var displayScale

    private func submit(_ prompt: CaptchaPrompt) {
        if !answer.isEmpty {
            prompt.submit(answer)
            answer = ""
        }
    }

    private func cancel(_ prompt: CaptchaPrompt) {
        prompt.cancel()
        answer = ""
    }

    func body(content: Content) -> some View {
        content
            .customAlert(
                "The action is being performed too often",
                item: $captchaPrompt,
            ) { prompt in
                let captcha = prompt.captcha
                Text(verbatim: captcha.hint)
                CacheableAsyncImage(
                    size: CGSize(
                        width: captcha.width,
                        height: captcha.height,
                    ),
                    url: captcha.url,
                    cachePolicy: .reloadIgnoringLocalCacheData,
                    content: { image in
                        image
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    },
                    placeholder: {
                        Color.clear
                    },
                )
                // Account for https://github.com/grishka/Smithereen/issues/255
                .frame(
                    width: CGFloat(captcha.width) * 2,
                    height: CGFloat(captcha.height) * 2,
                )
                .padding()
                CaptchaTextField(answer: $answer) {
                    submit(prompt)
                }
            } actions: { prompt in
                MultiButton {
                    Button("Cancel", role: .cancel) {
                        cancel(prompt)
                    }
                    Button("Submit") {
                        submit(prompt)
                    }
                    .disabled(answer.isEmpty)
                }
            }
            .configureCustomAlert(.default.alert(.default.alignment(.center)))
            .colorScheme(.light)
    }
}

private struct CaptchaTextField: View {
    @Binding var answer: String
    var submit: () -> Void
    @FocusState private var textFieldFocused

    var body: some View {
        TextField("captcha_code", text: $answer)
            .focused($textFieldFocused)
            .textFieldStyle(.roundedBorder)
            .multilineTextAlignment(.center)
            .font(.body.monospaced())
            .padding(4)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .keyboardType(.asciiCapable)
            .onSubmit(submit)
            .onAppear {
                textFieldFocused = true
            }
    }
}

extension View {
    func captchaPrompt(_ prompt: Binding<CaptchaPrompt?>) -> some View {
        modifier(CaptchaPromptViewModifier(captchaPrompt: prompt))
    }
}
