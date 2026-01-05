import Foundation
import SmithereenAPI

enum Constants {
    static let clientID = URL(
        string: Bundle.main.object(
            forInfoDictionaryKey: "SMITHEREEN_CLIENT_ID"
        ) as! String
    )!

    static let appURLScheme: String = {
        let urlTypes = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleURLTypes"
        ) as! [Any]
        let dict = urlTypes.first as! [String : Any]
        let schemes = dict["CFBundleURLSchemes"] as! [String]
        return schemes[0]
    }()

    static let oauthRedirectURL = URL(string: "\(appURLScheme)://oauth-callback")!

    static let appVersion = Bundle
        .main
        .object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String

    static let userAgent = "\(Bundle.main.bundleIdentifier!)/\(appVersion)"

    static let bugReportEmail = Bundle.main
        .object(forInfoDictionaryKey: "SMITHEREEN_BUG_REPORT_EMAIL") as! String
}

extension Permission {
    static let requiredPermissions: [Permission] = [
        .account,
        .newsfeed,
        .notifications,
        .offline,
        .friends(),
        .groups(),
        .likes(),
        .messages(),
        .photos(),
        .wall(),
    ]
}
