import Prefire
import SwiftUI

struct AuthView: View {
    let api: any AuthenticationService
    @EnvironmentObject private var palette: PaletteHolder
    @AppStorage(.smithereenInstance) private var instanceAddress: String
    @StateObject private var errorObserver = ErrorObserver()
    @State private var email: String = ""
    @State private var password: String = ""

    private var instanceURL: URL? {
        if instanceAddress.isEmpty {
            return nil
        }
        var urlComponents: URLComponents
        if instanceAddress.starts(with: "http://")
            || instanceAddress.starts(with: "https://")
        {
            guard let c = URLComponents(string: instanceAddress) else {
                return nil
            }
            urlComponents = c
        } else if let components = URLComponents(string: instanceAddress),
            components.scheme != nil
        {
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
                case AuthenticationError.instanceNotFound:
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
                        TextField("Instance domain", text: $instanceAddress)
                            .textContentType(.URL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
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
