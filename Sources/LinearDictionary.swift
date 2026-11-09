// NOTE: This whole file is a severe case of premature optimization.
// I really enjoyed writing this code though.

protocol LinearDictionaryKeyValueSelector {
    associatedtype Element
    associatedtype Selected

    func callAsFunction(_ element: Element) -> Selected
}

protocol LinearDictionaryDefaultInitializableKeyValueSelector
    : LinearDictionaryKeyValueSelector
{
    init()
}

struct LinearDictionaryClosureBasedSelector<Element, Selected>
    : LinearDictionaryKeyValueSelector
{
    let closure: (Element) -> Selected
    func callAsFunction(_ element: Element) -> Selected {
        closure(element)
    }
}

struct LinearDictionaryIdentitySelector<Element>
    : LinearDictionaryDefaultInitializableKeyValueSelector
{
    func callAsFunction(_ element: Element) -> Element {
        return element
    }
}

struct LinearDictionaryTupleKeySelector<Key, Value>
    : LinearDictionaryDefaultInitializableKeyValueSelector
{
    func callAsFunction(_ element: (Key, Value)) -> Key {
        element.0
    }
}

struct LinearDictionaryTupleValueSelector<Key, Value>
    : LinearDictionaryDefaultInitializableKeyValueSelector
{
    func callAsFunction(_ element: (Key, Value)) -> Value {
        element.1
    }
}

/// A dictionary backed by some other collection that for small number of entries
/// is faster than `Dictionary` from the standard library, and also doesn't require
/// the key type to be hashable.
struct GenericLinearDictionary<
    Storage: Sequence,
    KeySelector: LinearDictionaryKeyValueSelector,
    ValueSelector: LinearDictionaryKeyValueSelector
>
    where Storage.Element == KeySelector.Element,
          Storage.Element == ValueSelector.Element
{
    private var storage: Storage
    private var keySelector: KeySelector
    private var valueSelector: ValueSelector

    private init(
        _ storage: Storage,
        keySelector: KeySelector,
        valueSelector: ValueSelector,
    ) {
        self.storage = storage
        self.keySelector = keySelector
        self.valueSelector = valueSelector
    }

    init<Key>(
        _ storage: Storage,
        keySelector: @escaping (Storage.Element) -> Key,
    )
        where
            KeySelector == LinearDictionaryClosureBasedSelector<Storage.Element, Key>,
            ValueSelector == LinearDictionaryIdentitySelector<Storage.Element>
    {
        self.storage = storage
        self.keySelector = LinearDictionaryClosureBasedSelector(closure: keySelector)
        self.valueSelector = LinearDictionaryIdentitySelector()
    }

    init<Key, Value>(_ storage: Storage)
        where
            Storage.Element == (Key, Value),
            KeySelector == LinearDictionaryTupleKeySelector<Key, Value>,
            ValueSelector == LinearDictionaryTupleValueSelector<Key, Value>
    {
        self.storage = storage
        self.keySelector = LinearDictionaryTupleKeySelector()
        self.valueSelector = LinearDictionaryTupleValueSelector()
    }

    init<Key, Value>()
        where
            Storage: RangeReplaceableCollection,
            KeySelector == LinearDictionaryTupleKeySelector<Key, Value>,
            ValueSelector == LinearDictionaryTupleValueSelector<Key, Value>
    {
        self.storage = .init()
        self.keySelector = LinearDictionaryTupleKeySelector()
        self.valueSelector = LinearDictionaryTupleValueSelector()
    }

    subscript<Key, Value>(key: Key) -> Value?
        where Key: Equatable, KeySelector.Selected == Key, ValueSelector.Selected == Value
    {
        for element in storage {
            if keySelector(element) == key {
                return valueSelector(element)
            }
        }
        return nil
    }
}

typealias LinearDictionaryWithClosureBasedKeySelector<Key: Equatable, Storage: Sequence> =
    GenericLinearDictionary<
        Storage,
        LinearDictionaryClosureBasedSelector<Storage.Element, Key>,
        LinearDictionaryIdentitySelector<Storage.Element>,
    >

typealias LinearDictionary<Key, Value, Storage: Sequence> =
    GenericLinearDictionary<
        Storage,
        LinearDictionaryTupleKeySelector<Key, Value>,
        LinearDictionaryTupleValueSelector<Key, Value>,
    >
    where Storage.Element == (Key, Value)

typealias ArrayBasedDictionary<Key, Value> =
    LinearDictionary<Key, Value, Array<(Key, Value)>>

extension GenericLinearDictionary: Sendable
    where Storage: Sendable,
          KeySelector: Sendable,
          ValueSelector: Sendable
{
}

extension GenericLinearDictionary: Sequence {
    typealias Element = Storage.Element
    typealias Iterator = Storage.Iterator

    func makeIterator() -> Storage.Iterator {
        storage.makeIterator()
    }

    func withContiguousStorageIfAvailable<R>(
        _ body: (UnsafeBufferPointer<Storage.Element>
    ) throws -> R) rethrows -> R? {
        try storage.withContiguousStorageIfAvailable(body)
    }
}

extension GenericLinearDictionary: Collection where Storage: Collection {
    typealias Index = Storage.Index

    var startIndex: Storage.Index {
        storage.startIndex
    }

    var endIndex: Storage.Index {
        storage.endIndex
    }

    subscript(position: Storage.Index) -> Storage.Element {
        _read {
            yield storage[position]
        }
    }

    func index(after i: Storage.Index) -> Storage.Index {
        storage.index(after: i)
    }

    func formIndex(after i: inout Storage.Index) {
        storage.formIndex(after: &i)
    }

    var count: Int {
        storage.count
    }

    var isEmpty: Bool {
        storage.isEmpty
    }
}

extension GenericLinearDictionary: MutableCollection where Storage: MutableCollection {
    subscript(position: Storage.Index) -> Storage.Element {
        _read {
            yield storage[position]
        }
        _modify {
            yield &storage[position]
        }
    }
}

extension GenericLinearDictionary: BidirectionalCollection where Storage: BidirectionalCollection {
    func index(before i: Storage.Index) -> Storage.Index {
        storage.index(before: i)
    }

    func formIndex(before i: inout Storage.Index) {
        storage.formIndex(before: &i)
    }
}

extension GenericLinearDictionary: RangeReplaceableCollection
    where Storage: RangeReplaceableCollection,
          KeySelector: LinearDictionaryDefaultInitializableKeyValueSelector,
          ValueSelector: LinearDictionaryDefaultInitializableKeyValueSelector
{
    init() {
        storage = .init()
        keySelector = .init()
        valueSelector = .init()
    }

    mutating func replaceSubrange<C: Collection>(
        _ subrange: Range<Storage.Index>,
        with newElements: C,
    ) where Storage.Element == C.Element {
        storage.replaceSubrange(subrange, with: newElements)
    }

    mutating func reserveCapacity(_ n: Int) {
        storage.reserveCapacity(n)
    }

    mutating func append(_ newElement: Storage.Element) {
        storage.append(newElement)
    }
}
