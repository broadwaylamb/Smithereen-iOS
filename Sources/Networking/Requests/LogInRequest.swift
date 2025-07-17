import Hammond

@POST("/account/login")
@EncodableRequest
struct LogInRequest: DecodableRequestProtocol {
    var username: String
    var password: String

    static func extractResult(
        from response: some ResponseProtocol<ResponseBody>
    ) throws {
        if response.statusCode != .found {
            throw AuthenticationError.invalidCredentials
        }
    }
}
