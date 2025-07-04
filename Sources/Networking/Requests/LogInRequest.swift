import Hammond

@POST("/account/login")
@EncodableRequest
struct LogInRequest: DecodableRequestProtocol {
    var username: String
    var password: String

    static func extractResult(
        from response: some ResponseProtocol<ResponseBody>
    ) throws -> Void {
        if response.statusCode != .found {
            throw AuthenticationError.invalidCredentials
        }
    }
}
