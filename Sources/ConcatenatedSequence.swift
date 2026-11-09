struct ConcatenatedSequence<LHS: Sequence, RHS: Sequence>
    where LHS.Element == RHS.Element
{
    let lhs: LHS
    let rhs: RHS

    init(_ lhs: LHS, _ rhs: RHS) {
        self.lhs = lhs
        self.rhs = rhs
    }
}

extension ConcatenatedSequence: Sequence {
    typealias Element = LHS.Element

    struct Iterator: IteratorProtocol {
        typealias Element = LHS.Element

        fileprivate var lhs: LHS.Iterator
        fileprivate var rhs: RHS.Iterator

        mutating func next() -> LHS.Element? {
            lhs.next() ?? rhs.next()
        }
    }

    func makeIterator() -> Iterator {
        Iterator(lhs: lhs.makeIterator(), rhs: rhs.makeIterator())
    }

    var underestimatedCount: Int {
        lhs.underestimatedCount + rhs.underestimatedCount
    }
}
