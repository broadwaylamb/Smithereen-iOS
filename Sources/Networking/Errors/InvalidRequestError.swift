import Foundation
import SmithereenAPI

struct InvalidRequestError: TechnicalError {
    var urlRequest: URLRequest
    var error: SmithereenAPIError

    var technicalInfo: String {
        let message: String
        switch error.code {
        case .executeFailedToCompile:
            message = executeError(isCompilationError: true)
        case .executeRuntimeError:
            message = executeError(isCompilationError: false)
        default:
            message = error.message
        }

        return """
            \(message)
            
            Problematic request:
            \(urlRequest.render())
            """
    }

    private func executeError(isCompilationError: Bool) -> String {
        let process = isCompilationError ? "compiling" : "executing"
        if let code = error[requestParameter: "code"] {
            return """
            An error occurred when \(process) the following Execute script:
            \(code)
            
            Error:
            \(error.message)
            """
        } else {
            return """
            An error occurred when \(process) an Execute script.
            
            Error:
            \(error.message)
            """
        }
    }
}

extension InvalidRequestError: LocalizedError {
    var errorDescription: String? {
        String(localized: """
            Incorrect request format. \
            Please report this error to the application developer.
            """)
    }
}
