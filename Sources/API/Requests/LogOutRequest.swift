import Hammond
import SwiftSoup

@GET("/account/logout")
@EncodableRequest
struct LogOutRequest: DecodableRequestProtocol {
    typealias Result = Void

    @Query var csrf: String
}
