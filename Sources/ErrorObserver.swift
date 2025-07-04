import SwiftUI

@MainActor
final class ErrorObserver: ObservableObject {
    @Published var error: (any Error)?

    fileprivate var errorAlertShown: Binding<Bool> {
        Binding {
            self.error != nil
        } set: {
            if !$0 {
                self.error = nil
            }
        }
    }

    nonisolated func runCatching(_ block: @Sendable () async throws -> Void) async {
        do {
            return try await block()
        } catch {
            await MainActor.run {
                self.error = error
            }
        }
    }

    nonisolated func runCatching(
        _ block: @Sendable () async throws -> Void,
        onError: @MainActor (any Error) -> Void
    ) async {
        do {
            return try await block()
        } catch {
            await MainActor.run {
                onError(error)
                self.error = error
            }
        }
    }
}

extension View {
    func alert(_ errorObserver: ErrorObserver) -> some View {
        alert(
            isPresented: errorObserver.errorAlertShown,
            error: errorObserver.error.map(AnyLocalizedError.init)
        ) {
            Button("OK", action: {})
        }
    }
}
