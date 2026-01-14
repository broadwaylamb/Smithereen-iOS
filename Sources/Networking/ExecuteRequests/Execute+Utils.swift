import Foundation
import SmithereenAPI

extension Execute {
    static func scriptResource(_ name: String) -> String {
        try! String(
            contentsOfFile: Bundle
                .main
                .path(forResource: "execute.\(name)", ofType: "js")!,
            encoding: .utf8,
        )
    }
}

