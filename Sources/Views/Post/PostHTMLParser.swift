import Foundation
import SwiftSoup

// All the text formating supported by Smithereen in posts.
// https://github.com/grishka/Smithereen/blob/c530e8b8fcb8145b8e78de142710736e6bf46c3c/src/main/java/smithereen/text/MicroFormatAwareHTMLWhitelist.java#L27

struct PostText: Equatable {
    var blocks: [PostTextBlock]

    init() {
        blocks = []
    }

    init(_ element: Element) {
        let parser = Parser()
        element.traverse(parser)
        blocks = parser.result
    }

    init(html: String) throws {
        self.init(try SwiftSoup.parse(html))
    }

    var isEmpty: Bool {
        blocks.isEmpty
    }
}

extension PostText: ExpressibleByStringLiteral {
    typealias StringLiteralType = String

    typealias ExtendedGraphemeClusterLiteralType = String

    typealias UnicodeScalarLiteralType = String

    init(stringLiteral value: String) {
        blocks = [.paragraph(content: [.text(value)])]
    }
}

enum PostTextBlock: Sendable, Equatable {
    case paragraph(content: [PostTextInlineNode])
    case quote(children: [PostTextBlock])
    case codeBlock(content: String)
}

enum PostTextInlineNode: Sendable, Equatable {
    case text(String)
    case lineBreak
    case code(children: [PostTextInlineNode])
    case strong(children: [PostTextInlineNode])
    case emphasis(children: [PostTextInlineNode])
    case underline(children: [PostTextInlineNode])
    case strikethrough(children: [PostTextInlineNode])
    case `subscript`(children: [PostTextInlineNode])
    case superscript(children: [PostTextInlineNode])
    case link(URL, children: [PostTextInlineNode])
}

private final class Parser: NodeVisitor {
    typealias Error = Never

    private var codeBlockDepth = 0
    private var lastWasWhite = false
    private var stripLeadingWhitespace = true

    private var code = ""
    private var blocks: [[PostTextBlock]] = []
    private var inlineNodes: [[PostTextInlineNode]] = []

    var result: [PostTextBlock] {
        if let blocks = blocks.first {
            return blocks
        }
        if let inlineNodes = inlineNodes.first {
            return [.paragraph(content: inlineNodes)]
        }

        return []
    }

    func head(_ node: Node, _ depth: Int) {
        if let element = node as? Element {
            switch element.tagNameNormal() {
            case "pre":
                codeBlockDepth += 1
                return
            case "blockquote":
                stripLeadingWhitespace = true
                blocks.append([])
            case "p":
                stripLeadingWhitespace = true
                inlineNodes = []
            case "br":
                stripLeadingWhitespace = true
            case "a", "b", "i", "u", "s", "code", "sub", "sup":
                inlineNodes.append([])
            default:
                break
            }
        }
    }

    func tail(_ node: Node, _ depth: Int) {
        if let textNode = node as? TextNode {
            let text = textNode.getWholeText()
            if codeBlockDepth > 0 {
                code += text
            } else {
                appendInlineNode(.text(normalizedWhitespace(text)))
            }
        } else if let element = node as? Element {
            let tagName = element.tagNameNormal()
            switch tagName {
            case "p":
                if !inlineNodes.isEmpty {
                    let content = inlineNodes.removeLast()
                    inlineNodes = []
                    appendBlock(.paragraph(content: content))
                }
            case "pre":
                codeBlockDepth -= 1
                if codeBlockDepth == 0 {
                    appendBlock(.codeBlock(content: code))
                    code = ""
                }
            case "blockquote":
                var children = blocks.pop() ?? []
                if children.isEmpty {
                    let inlineNodes = self.inlineNodes.first ?? []
                    self.inlineNodes = []
                    children = [.paragraph(content: inlineNodes)]
                }
                appendBlock(.quote(children: children))
            case "a":
                let href = (try? element.attr("href")) ?? ""
                if !href.isEmpty, let url = URL(string: href) {
                    finalizeInlineNode { .link(url, children: $0) }
                } else if !inlineNodes.isEmpty {
                    inlineNodes.removeLast()
                }
            case "b":
                finalizeInlineNode(PostTextInlineNode.strong)
            case "i":
                finalizeInlineNode(PostTextInlineNode.emphasis)
            case "u":
                finalizeInlineNode(PostTextInlineNode.underline)
            case "s":
                finalizeInlineNode(PostTextInlineNode.strikethrough)
            case "code":
                finalizeInlineNode(PostTextInlineNode.code)
            case "sub":
                finalizeInlineNode(PostTextInlineNode.subscript)
            case "sup":
                finalizeInlineNode(PostTextInlineNode.superscript)
            case "br":
                appendInlineNode(.lineBreak)
            default:
                break
            }
        }
    }

    private func appendBlock(_ block: PostTextBlock) {
        if blocks.isEmpty {
            blocks.append([])
        }
        blocks[blocks.endIndex - 1].append(block)
    }

    private func finalizeInlineNode(_ createNode: ([PostTextInlineNode]) -> PostTextInlineNode) {
        if let children = inlineNodes.pop() {
            appendInlineNode(createNode(children))
        }
    }

    private func appendInlineNode(_ node: PostTextInlineNode) {
        if inlineNodes.isEmpty {
            inlineNodes.append([])
        }
        inlineNodes[inlineNodes.endIndex - 1].append(node)
    }

    private func normalizedWhitespace(_ string: String) -> String {
        var accum = [Character]()
        var reachedNonWhite: Bool = false

        for c in string {
            if (c == " " || c == "\n" || c == "\r" || c == "\t" || c == "\u{000C}") {
                if stripLeadingWhitespace && !reachedNonWhite || lastWasWhite {
                    continue
                }
                accum.append(" ")
                lastWasWhite = true
            } else {
                accum.append(c)
                lastWasWhite = false
                reachedNonWhite = true
                stripLeadingWhitespace = false
            }
        }
        return String(accum)
    }
}

private extension Array {
    mutating func pop() -> Element? {
        return isEmpty ? nil : removeLast()
    }
}
