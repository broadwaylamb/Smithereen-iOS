import Hammond
import HammondMacros

@POST("/account/login")
@EncodableRequest
struct LogInRequest: DecodableRequestProtocol, IgnoreRedirects {
    var username: String
    var password: String

    func extractResult(
        from response: some ResponseProtocol<ResponseBody>
    ) throws {
        if response.statusCode != .found {
            throw AuthenticationError.invalidCredentials
        }
    }
}
