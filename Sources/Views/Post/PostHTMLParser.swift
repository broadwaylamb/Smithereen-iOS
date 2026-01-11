import Foundation
import SmithereenAPI

// All the text formating supported by Smithereen in posts.
// https://smithereen.software/docs/api/text-formatting/

struct PostText: Equatable {
    var blocks: [PostTextBlock]

    init() {
        blocks = []
    }

    init(html: String) {
        let delegate = Parser()
        let parser = HTMLParser(options: [])
        parser.parse(html, delegate: delegate)
        blocks = delegate.result
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
    case link(URL, mentionedUser: UserID?, children: [PostTextInlineNode])
}

private final class Parser: HTMLParserDelegate {

    private var codeBlockDepth = 0
    private var lastWasWhite = false
    private var stripLeadingWhitespace = true

    private var code = ""
    private var linkURL: URL?
    private var mentionedUserID: UserID?
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

    func startElement(_ tagName: String, attributes: [String : String]) {
        switch tagName.lowercased(with: .posix) {
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
        case "a":
            linkURL = attributes["href"].flatMap(URL.init)
            if attributes["class"] == "mention" {
                mentionedUserID = attributes["data-user-id"]
                    .flatMap(UserID.RawValue.init)
                    .map(UserID.init)
            }
            inlineNodes.append([])
        case "b", "i", "u", "s", "code", "sub", "sup":
            inlineNodes.append([])
        default:
            break
        }
    }

    func foundCharacters(_ text: String) {
        if codeBlockDepth > 0 {
            code += text
        } else {
            appendInlineNode(.text(normalizedWhitespace(text)))
        }
    }

    func endElement(_ tagName: String) {
        switch tagName.lowercased(with: .posix) {
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
            if let url = linkURL {
                finalizeInlineNode {
                    .link(url, mentionedUser: mentionedUserID, children: $0)
                }
            } else if !inlineNodes.isEmpty {
                inlineNodes.removeLast()
            }
            linkURL = nil
            mentionedUserID = nil
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

    private func appendBlock(_ block: PostTextBlock) {
        if blocks.isEmpty {
            blocks.append([])
        }
        blocks[blocks.endIndex - 1].append(block)
    }

    private func finalizeInlineNode(
        _ createNode: ([PostTextInlineNode]) -> PostTextInlineNode,
    ) {
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
            if c == " " || c == "\n" || c == "\r" || c == "\t" || c == "\u{000C}" {
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

extension Array {
    fileprivate mutating func pop() -> Element? {
        return isEmpty ? nil : removeLast()
    }
}
