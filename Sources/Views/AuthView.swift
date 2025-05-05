import SwiftUI

private struct InputFields: View {
    @Binding var instanceURL: String
    @Binding var email: String
    @Binding var password: String
    var body: some View {
        TextField("Instance domain", text: $instanceURL)
            .textContentType(.URL)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
        TextField("Email or username", text: $email)
            .textContentType(.emailAddress)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
        SecureField("Password", text: $password)
            .textContentType(.password)
    }
}

struct AuthView: View {
    @State private var instanceURL: String = ""
    @State private var email: String = ""
    @State private var password: String = ""

    private func logIn() {

    }

    var body: some View {
        VStack {
            Text("Smithereen")
                .font(.system(.largeTitle, design: .serif)) // TODO: Use a more appropriate font
                .foregroundStyle(Color.white)
                .padding(EdgeInsets(top: 100, leading: 0, bottom: 0, trailing: 0))
            Form {
                Section {
                    InputFields(
                        instanceURL: $instanceURL,
                        email: $email,
                        password: $password,
                    )
                }
                Section {
                    Button {
                        logIn()
                    } label: {
                        Text("Log in")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                Section {
                    Button {

                    } label: {
                        Text("Forgot password?")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.white)
                    .listRowBackground(Color.clear)
                }
            }
            .environment(\.colorScheme, .light)
            .onSubmit(logIn)
            .listSectionSpacingPolyfill(8)
            .scrollDisabledPolyfill(true)
            .scrollContentBackgroundPolyfill(.hidden)
        }
        .background(alignment: .center) {
            Color.accent.ignoresSafeArea()
        }
        .preferredColorScheme(.dark) // Make sure the status bar text color is white
    }
}

#Preview("Authentication") {
    AuthView()
}
