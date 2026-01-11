import Foundation
import SmithereenAPI

// All the text formating supported by Smithereen in posts.
// https://smithereen.software/docs/api/text-formatting/

struct RichText: Equatable {
    var blocks: [Block]

    init() {
        blocks = []
    }

    init(html: String) {
        let delegate = Parser()
        let parser = HTMLParser()
        parser.parse(html, delegate: delegate)
        blocks = delegate.result
    }

    var isEmpty: Bool {
        blocks.isEmpty
    }

    enum Block: Sendable, Equatable {
        case paragraph(content: [InlineNode])
        case quote(children: [Block])
        case codeBlock(content: String)
    }

    enum InlineNode: Sendable, Equatable {
        case text(String)
        case lineBreak
        case code(children: [InlineNode])
        case strong(children: [InlineNode])
        case emphasis(children: [InlineNode])
        case underline(children: [InlineNode])
        case strikethrough(children: [InlineNode])
        case `subscript`(children: [InlineNode])
        case superscript(children: [InlineNode])
        case link(URL, mentionedUser: UserID?, children: [InlineNode])
    }
}

extension RichText: ExpressibleByStringLiteral {
    typealias StringLiteralType = String

    typealias ExtendedGraphemeClusterLiteralType = String

    typealias UnicodeScalarLiteralType = String

    init(stringLiteral value: String) {
        blocks = [.paragraph(content: [.text(value)])]
    }
}

private final class Parser: HTMLParserDelegate {

    private var codeBlockDepth = 0
    private var lastWasWhite = false
    private var stripLeadingWhitespace = true

    private var code = ""
    private var linkURL: URL?
    private var mentionedUserID: UserID?
    private var blocks: [[RichText.Block]] = []
    private var inlineNodes: [[RichText.InlineNode]] = []

    var result: [RichText.Block] {
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
            finalizeInlineNode(RichText.InlineNode.strong)
        case "i":
            finalizeInlineNode(RichText.InlineNode.emphasis)
        case "u":
            finalizeInlineNode(RichText.InlineNode.underline)
        case "s":
            finalizeInlineNode(RichText.InlineNode.strikethrough)
        case "code":
            finalizeInlineNode(RichText.InlineNode.code)
        case "sub":
            finalizeInlineNode(RichText.InlineNode.subscript)
        case "sup":
            finalizeInlineNode(RichText.InlineNode.superscript)
        case "br":
            appendInlineNode(.lineBreak)
        default:
            break
        }
    }

    private func appendBlock(_ block: RichText.Block) {
        if blocks.isEmpty {
            blocks.append([])
        }
        blocks[blocks.endIndex - 1].append(block)
    }

    private func finalizeInlineNode(
        _ createNode: ([RichText.InlineNode]) -> RichText.InlineNode,
    ) {
        if let children = inlineNodes.pop() {
            appendInlineNode(createNode(children))
        }
    }

    private func appendInlineNode(_ node: RichText.InlineNode) {
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
