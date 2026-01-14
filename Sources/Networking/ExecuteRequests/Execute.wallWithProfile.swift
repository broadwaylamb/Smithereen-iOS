import Foundation
import SmithereenAPI

extension Execute<Wall.Get.Extended, Wall.Get.Extended.Result> {
    private static let script = scriptResource("wallWithProfile")

    /// Like `Wall.Get` but always returns the wall's owner `User`/`Group` object in the `profiles`/`groups`
    /// array of the result, even if the wall is empty.
    static func wallWithProfile(
        ownerID: ActorID? = nil,
        offset: Int? = nil,
        count: Int? = nil,
        filter: Wall.Get.Filter? = nil,
        fields: [ActorField],
    ) -> Self {
        Execute(
            code: script,
            args: Wall.Get.Extended(
                ownerID: ownerID,
                offset: offset,
                count: count,
                filter: filter,
                fields: fields,
            )
        )
    }
}
