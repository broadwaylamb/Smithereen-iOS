import SwiftSoup

/// Like `SwiftSoup.NodeVisitor` but with typed throws for better type safety
protocol NodeVisitor {
    associatedtype Error: Swift.Error

    func head(_ node: Node, _ depth: Int) throws(Error)

    func tail(_ node: Node, _ depth: Int) throws(Error)
}

extension Node {
    func traverse<Visitor: NodeVisitor>(_ visitor: Visitor) throws(Visitor.Error) {
        var node: Node? = self
        var depth: Int = 0

        while let currentNode = node {
            try visitor.head(currentNode, depth)
            if currentNode.hasChildNodes() {
                node = currentNode.childNode(0)
                depth += 1
            } else {
                var node2: Node? = currentNode
                while let currentNode = node2,
                    !currentNode.hasNextSibling() && depth > 0
                {
                    let parent = currentNode.parent()
                    try visitor.tail(currentNode, depth)
                    node2 = parent
                    depth -= 1
                }
                if let currentNode = node2 {
                    let nextSib = currentNode.nextSibling()
                    try visitor.tail(currentNode, depth)
                    if currentNode === self {
                        break
                    }
                    node = nextSib
                }
            }
        }
    }
}
