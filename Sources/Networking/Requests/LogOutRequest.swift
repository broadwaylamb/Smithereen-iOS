import Hammond
import HammondMacros
import SwiftSoup

@GET("/account/logout")
struct LogOutRequest: DecodableRequestProtocol, RequiresCSRF {
    typealias Result = Void
}
