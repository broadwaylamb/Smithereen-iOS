import Foundation

/// An error that occured because of incrorrect assumptions in the application code.
protocol TechnicalError: Error {
    var technicalInfo: String { get }
}

extension TechnicalError where Self: LocalizedError {
    var recoverySuggestion: String? {
        String(localized: "Please report this error to the application developer")
    }
}

extension [any CodingKey] {
    func render() -> String {
        var r = "<root>"
        for key in self {
            if let int = key.intValue {
                r += "[\(int)]"
            } else {
                r += ".\(key.stringValue)"
            }
        }
        return r
    }
}

extension EncodingError: TechnicalError {
    var technicalInfo: String {
        switch self {
        case .invalidValue(let attemptedValue, let context):
            var info = """
                EncodingError.invalidValue
                
                Coding path: \(context.codingPath.render())
                
                When attempting to encode the following value:
                \(String(reflecting: attemptedValue))
                
                Debug description:
                \(context.debugDescription)
                """

            if let underlyingError = context.underlyingError {
                info += """
                    
                    Underlying error:
                    """
                if let underlyingTechnicalError = underlyingError as? TechnicalError {
                    info += underlyingTechnicalError.technicalInfo
                } else {
                    info += String(describing: underlyingError)
                }
            }
            return info
        @unknown default:
            return String(describing: self)
        }
    }
}

extension DecodingError: TechnicalError {
    private var caseNameAndContext: (String, DecodingError.Context)? {
        switch self {
        case .typeMismatch(_, let c):
            return ("typeMismatch", c)
        case .valueNotFound(_, let c):
            return ("valueNotFound", c)
        case .keyNotFound(_, let c):
            return ("keyNotFound", c)
        case .dataCorrupted(let c):
            return ("dataCorrupted", c)
        @unknown default:
            return nil
        }
    }

    var technicalInfo: String {
        guard let (caseName, context) = caseNameAndContext else {
            return String(describing: self)
        }
        var info = """
            DecodingError.\(caseName)
            
            Coding path: \(context.codingPath.render())
            """

        switch self {
        case .typeMismatch(let expectedType, _), .valueNotFound(let expectedType, _):
            info += """
                
                Expected type: \(expectedType)
                """
        case .keyNotFound(let codingKey, _):
            let renderedKey = codingKey.intValue.map { "Index \($0)" }
                ?? "\"\(codingKey.stringValue)\""
            info += """
                
                Missing key: \(renderedKey)
                """
        default: break
        }

        info += """
            
            Debug description: \(context.debugDescription)
            """

        if let underlyingError = context.underlyingError {
            info += """
                
                Underlying error:
                """
            if let underlyingTechnicalError = underlyingError as? TechnicalError {
                info += underlyingTechnicalError.technicalInfo
            } else {
                info += String(describing: underlyingError)
            }
        }

        return info
    }
}
