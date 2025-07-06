import SwiftUI
import Prefire

private struct InputFields: View {
    @Binding var instanceAddress: String
    @Binding var email: String
    @Binding var password: String
    var body: some View {
        TextField("Instance domain", text: $instanceAddress)
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
    let api: any AuthenticationService
    @EnvironmentObject private var palette: PaletteHolder
    @AppStorage(.smithereenInstance) private var instanceAddress: String = ""
    @StateObject private var errorObserver = ErrorObserver()
    @State private var email: String = ""
    @State private var password: String = ""

    private var instanceURL: URL? {
        if instanceAddress.isEmpty {
            return nil
        }
        var urlComponents: URLComponents
        if instanceAddress.starts(with: "http://") || instanceAddress.starts(with: "https://") {
            guard let c = URLComponents(string: instanceAddress) else {
                return nil
            }
            urlComponents = c
        } else if let components = URLComponents(string: instanceAddress), components.scheme != nil {
            return nil
        } else {
            guard let c = URLComponents(string: "https://" + instanceAddress) else {
                return nil
            }
            urlComponents = c
        }
        if urlComponents.host?.isEmpty ?? true {
            return nil
        }
        urlComponents.queryItems = nil
        urlComponents.path = ""
        return urlComponents.url
    }

    private var areInputsValid: Bool {
        instanceURL != nil && !email.isEmpty && !password.isEmpty
    }

    private func logIn() {
        guard let instanceURL = self.instanceURL else { return }
        Task {
            await errorObserver.runCatching {
                try await api.authenticate(
                    instance: instanceURL,
                    email: email,
                    password: password
                )
            } onError: { error in
                switch error {
                case AuthenticationError.instanceNotFound,
                    AuthenticationError.notSmithereenInstance:
                    self.instanceAddress = ""
                default:
                    break
                }
            }
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            Spacer(minLength: 0)
            VStack {
                Image(.logoWithText)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 330)
                    .padding(.horizontal, 20)
                    .shadow(color: .black.opacity(0.15), radius: 4, y: 3)
                    .accessibilityLabel(Text("Smithereen"))
                Form {
                    Section {
                        InputFields(
                            instanceAddress: $instanceAddress,
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
                        .disabled(instanceURL == nil)
                    }
                    Section {
                        Button {
                            // TODO
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
            .preferredColorScheme(.dark) // Make sure the status bar text color is white
            .alert(errorObserver)
            .padding(.top, 100)
            .frame(maxWidth: 440)
            Spacer(minLength: 0)
        }
        .background(alignment: .center) {
            palette.accent.ignoresSafeArea()
        }
    }
}

#Preview("Authentication") {
	AuthView(api: MockApi())
		.defaultAppStorage(UserDefaults())
		.snapshot(perceptualPrecision: 0.98)
}
