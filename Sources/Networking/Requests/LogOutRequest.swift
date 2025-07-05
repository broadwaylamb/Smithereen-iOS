import Hammond
import SwiftSoup

@GET("/account/logout")
struct LogOutRequest: DecodableRequestProtocol, RequiresCSRF {
    typealias Result = Void
}
