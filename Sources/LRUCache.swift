struct LRUCache<Key: Hashable, Value>: ~Copyable {
    private final class Node {
        let key: Key
        var value: Value

        // The actual owner of the nodes that is responsible for their deallocation
        // is the dictionary. Nodes themselves must not have strong references to each
        // other.
        unowned(unsafe) var previous: Node?
        unowned(unsafe) var next: Node?

        init(key: Key, value: Value) {
            self.key = key
            self.value = value
        }
    }

    private let capacity: Int
    private var dict: [Key : Node] = [:]

    private unowned(unsafe) var head: Node?
    private unowned(unsafe) var tail: Node?

    init(capacity: Int) {
        precondition(capacity > 0, "Capacity must be a positive number")
        self.capacity = capacity
    }

    /// Inserts a detached node at the beginning of the linked list
    private mutating func insert(_ node: Node) {
        assert(node.previous == nil && node.next == nil, "Node must be detached")
        if let prevHead = head {
            prevHead.previous = node
            node.next = prevHead
        } else {
            // The cache is empty
            tail = node
        }
        head = node
    }

    /// Detaches the node from the linked list
    private mutating func detach(_ node: Node) {
        assert(node.previous != nil || node.next != nil, "Node is already detached")
        if let prev = node.previous {
            prev.next = node.next
        } else {
            head = node.next
        }
        if let next = node.next {
            next.previous = node.previous
        } else {
            tail = node.previous
        }
        node.previous = nil
        node.next = nil
    }

    private mutating func lookUp(_ key: Key) -> Node? {
        guard let node = dict[key] else {
            return nil
        }
        if node === head {
            // Fast path: this value is already most recently used, no need to move it in
            // the linked list
            return node
        }
        detach(node)
        insert(node)
        return node
    }

    subscript(key: Key) -> Value? {
        mutating get {
            lookUp(key)?.value
        }
        set {
            if let existingNode = dict[key] {
                if let newValue {
                    existingNode.value = newValue
                    detach(existingNode)
                    insert(existingNode)
                } else {
                    detach(existingNode)
                    dict[key] = nil
                }
            } else if let newValue {
                if dict.count >= capacity, let tail {
                    // Evict the least recently used node
                    dict[tail.key] = nil
                    detach(tail)
                }
                let newNode = Node(key: key, value: newValue)
                dict[key] = newNode
                insert(newNode)
            }
        }
    }
}
