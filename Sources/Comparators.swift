import Foundation
import SmithereenAPI

extension ComparisonResult {
    fileprivate func withOrder(_ order: SortOrder) -> ComparisonResult {
        switch order {
        case .forward:
            return self
        case .reverse:
            switch self {
            case .orderedAscending:
                return .orderedDescending
            case .orderedSame:
                return .orderedSame
            case .orderedDescending:
                return .orderedAscending
            }
        }
    }
}

extension User {
    var nameForSorting: String { lastName ?? firstName }
}

extension String {
    fileprivate var startsWithLetter: Bool {
        first?.isLetter ?? false
    }
}

struct UserNameComparator: SortComparator {
    var order: SortOrder

    func compare(_ lhs: User, _ rhs: User) -> ComparisonResult {
        let lhsName = lhs.nameForSorting
        let rhsName = rhs.nameForSorting
        let lhsStartsWithLetter = lhsName.startsWithLetter
        let rhsStartsWithLetter = rhsName.startsWithLetter
        if lhsStartsWithLetter && !rhsStartsWithLetter {
            return .orderedAscending.withOrder(order)
        }
        if !lhsStartsWithLetter && rhsStartsWithLetter {
            return .orderedDescending.withOrder(order)
        }
        return lhsName.localizedCaseInsensitiveCompare(rhsName).withOrder(order)
    }
}
