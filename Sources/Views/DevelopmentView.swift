import SwiftUI
import SmithereenAPI

struct DevelopmentView: View {
    var api: APIService

    @EnvironmentObject private var errorObserver: ErrorObserver

    var body: some View {
        List {
            Section("API") {
                Button("Test Captcha") {
                    Task {
                        await errorObserver.runCatching {
                            try await api.invokeMethod(Utils.TestCaptcha())
                        }
                    }
                }
            }
        }
        .listStyle(.grouped)
        .colorScheme(.light)
    }
}

#Preview("Development") {
    DevelopmentView(api: MockApi())
        .environmentObject(PaletteHolder())
        .environmentObject(ErrorObserver())
}
