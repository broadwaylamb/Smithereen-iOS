extension Collection {
    func indexed() -> IndexedCollection<Self> {
        IndexedCollection(base: self)
    }
}

/// A drop-in replacement for `EnumeratedSequence` that conforms to `Collection`,
/// `BidirectionalCollection` and `RandomAccessCollection` until SE-0459 makes it into Swift.
struct IndexedCollection<Base: Collection>: Collection {
    typealias Element = (offset: Int, element: Base.Element)

    struct Index {
        fileprivate var base: Base.Index
        fileprivate var offset: Int
    }

    fileprivate var base: Base

    var startIndex: Index {
        Index(base: base.startIndex, offset: 0)
    }
    var endIndex: Index {
        Index(base: base.endIndex, offset: 0)
    }

    struct Iterator: IteratorProtocol {
        var i = 0
        var underlying: Base.Iterator

        mutating func next() -> Element? {
            defer {
                i += 1
            }
            return underlying.next().map { (offset: i, element: $0) }
        }
    }

    func makeIterator() -> Iterator {
        Iterator(underlying: base.makeIterator())
    }

    subscript(position: Index) -> Element {
        (offset: position.offset, element: base[position.base])
    }

    var isEmpty: Bool {
        base.isEmpty
    }

    var count: Int {
        base.count
    }

    private func offset(of index: Index) -> Int {
        index.base == base.endIndex ? base.count : index.offset
    }

    func index(_ i: Index, offsetBy distance: Int) -> Index {
        let index = base.index(i.base, offsetBy: distance)
        let offset = distance >= 0 ? i.offset : offset(of: i)
        return Index(base: index, offset: offset + distance)
    }

    func index(_ i: Index, offsetBy distance: Int, limitedBy limit: Index) -> Index? {
        base.index(i.base, offsetBy: distance, limitedBy: limit.base).map {
            let offset = distance >= 0 ? i.offset : offset(of: i)
            return Index(base: $0, offset: offset + distance)
        }
    }

    func distance(from start: Index, to end: Index) -> Int {
        if start.base == base.endIndex || end.base == base.endIndex {
            return base.distance(from: start.base, to: end.base)
        } else {
            return end.offset - start.offset
        }
    }

    func index(after i: Index) -> Index {
        Index(base: base.index(after: i.base), offset: i.offset + 1)
    }

    func formIndex(after i: inout Index) {
        base.formIndex(after: &i.base)
        i.offset += 1
    }
}

extension IndexedCollection.Index: Comparable {
    static func ==(lhs: Self, rhs: Self) -> Bool {
        lhs.base == rhs.base
    }

    static func <(lhs: Self, rhs: Self) -> Bool {
        lhs.base < rhs.base
    }
}

extension IndexedCollection: BidirectionalCollection
    where Base: BidirectionalCollection
{
    func index(before i: Index) -> Index {
        Index(base: base.index(before: i.base), offset: offset(of: i) - 1)
    }

    func formIndex(before i: inout Index) {
        base.formIndex(before: &i.base)
        i.offset = offset(of: i) - 1
    }
}

extension IndexedCollection: RandomAccessCollection
    where Base: RandomAccessCollection {}

extension IndexedCollection: Equatable where Base: Equatable {}
extension IndexedCollection: Hashable where Base: Hashable {}
