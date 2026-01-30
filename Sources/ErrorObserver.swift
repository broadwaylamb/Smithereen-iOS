import GRDB
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
        } catch let error as GRDB.DatabaseError {
            await MainActor.run {
                self.error = DatabaseError(wrapped: error)
            }
        } catch {
            if !error.isCancellationError {
                await MainActor.run {
                    self.error = error
                }
            }
        }
    }

    nonisolated func runCatching(
        _ block: @Sendable () async throws -> Void,
        onError: @MainActor (any Error) -> Void
    ) async {
        do {
            do {
                return try await block()
            } catch let error as GRDB.DatabaseError {
                throw DatabaseError(wrapped: error)
            }
        } catch {
            await MainActor.run {
                onError(error)
                if !error.isCancellationError {
                    self.error = error
                }
            }
        }
    }
}

private struct ErrorObserverViewModifier: ViewModifier {
    @ObservedObject var errorObserver: ErrorObserver

    @State private var technicalError: (any TechnicalError)?

    func body(content: Content) -> some View {
        content
            .alert(
                isPresented: errorObserver.errorAlertShown,
                error: errorObserver.error.map(AnyLocalizedError.init),
            ) { error in
                if let technicalError = error.error as? TechnicalError {
                    Button(MailComposeView.canSendEmail ? "Report a bug" : "Show technical data") {
                        self.technicalError = technicalError
                    }
                }
                Button("OK", action: {})
            } message: { _ in
            }
            .sheet(item: $technicalError, onDismiss: { technicalError = nil }) { error in
                if MailComposeView.canSendEmail {
                    MailComposeView(
                        recipients: [Constants.bugReportEmail],
                        subject: "Smithereen for iOS: bug report",
                        body: error.technicalInfo,
                    )
                } else {
                    NavigationView {
                        TechnicalDataTextView(error.technicalInfo)
                            .preferredColorScheme(.light)
                            .navigationTitle("Technical data")
                            .navigationBarStyleSmithereen()
                            .toolbar {
                                ToolbarItem(placement: .topBarTrailing) {
                                    Button("Done") {
                                        technicalError = nil
                                    }
                                }
                            }
                    }
                }
            }
    }
}

extension View {
    func alert(_ errorObserver: ErrorObserver) -> some View {
        modifier(ErrorObserverViewModifier(errorObserver: errorObserver))
    }
}
