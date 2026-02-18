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

                let aspectRatio = CGFloat(captcha.width) / CGFloat(captcha.height)
                let captchaWidth: CGFloat = 260
                let captchaHeight = captchaWidth / aspectRatio

                Text(verbatim: captcha.hint)
                CacheableAsyncImage(
                    size: CGSize(width: captchaWidth, height: captchaHeight),
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
                .frame(width: captchaWidth, height: captchaHeight)
                .padding()
                CaptchaTextField(answer: $answer) {
                    submit(prompt)
                }
                .frame(width: captchaWidth)
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
