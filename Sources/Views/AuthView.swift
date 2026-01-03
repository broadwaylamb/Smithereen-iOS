import Prefire
import SwiftUI
import SmithereenAPI

struct AuthView: View {
    @StateObject private var viewModel: AuthViewModel

    init(viewModel: AuthViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    @EnvironmentObject private var palette: PaletteHolder
    @StateObject private var errorObserver = ErrorObserver()
    @Environment(\.smithereenWebAuthenticationSession) var authenticationSession

    private func logIn() {
        Task {
            await errorObserver.runCatching {
                try await viewModel.logIn(session: authenticationSession)
            } onError: { error in
                switch error {
                case AuthenticationError.instanceNotFound:
                    self.viewModel.instanceAddress = ""
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
                        TextField("Instance domain", text: $viewModel.instanceAddress)
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
                        .disabled(!viewModel.isValidInstanceAddress)
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
    AuthView(viewModel: AuthViewModel(api: MockApi()))
        .defaultAppStorage(UserDefaults())
        .snapshot(perceptualPrecision: 0.98)
}
