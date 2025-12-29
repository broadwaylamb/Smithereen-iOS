import SwiftSoup
import Testing

@testable import Smithereen

struct PostHTMLParsingTests {
    @Test func testBlocks() {
        let postText = PostText(
            html: """
            <p>Paragraph with <br/> multiple <br/> lines.</p>
            <blockquote><p>Quote</p></blockquote>
            <pre>Code</pre>
            """
        )
        #expect(
            postText.toHTML() == """
            <p>
              Paragraph with
              <br/>
              multiple
              <br/>
              lines.
            </p>
            <blockquote>
              <p>
                Quote
              </p>
            </blockquote>
            <pre>Code</pre>
            """
        )
    }

    @Test func testNestedParagraphs() {
        let postText = PostText(
            html: """
            <p>Outer<p>Inner</p>Outer</p>
            """
        )

        #expect(
            postText.toHTML() == """
            <p>
              Outer
            </p>
            <p>
              Inner
            </p>
            """
         )
    }

    @Test func testQuoteInsideParagraph() {
        let postText = PostText(
            html: """
            <p>1<blockquote>Quote</blockquote>2</p>
            """
        )

        #expect(
            postText.toHTML() == """
            <p>
              1
            </p>
            <blockquote>
              <p>
                Quote
              </p>
            </blockquote>
            """
        )
    }

    @Test func testNestedQuotes() {
        let postText = PostText(
            html: """
            <blockquote><p>Outer</p><blockquote><p>Inner</p></blockquote><p>Outer</p></blockquote>
            """
        )

        #expect(
            postText.toHTML() == """
            <blockquote>
              <p>
                Outer
              </p>
              <blockquote>
                <p>
                  Inner
                </p>
              </blockquote>
              <p>
                Outer
              </p>
            </blockquote>
            """
        )
    }

    @Test func testNestedCodeBlocks() {
        let postText = PostText(
            html: """
            <pre>code<pre>nested</pre>code</pre>
            """
        )

        #expect(
            postText.toHTML() == """
            <pre>codenestedcode</pre>
            """
        )
    }

    @Test func testPlainText() {
        let postText = PostText(html: "Plain text")

        #expect(
            postText.toHTML() == """
            <p>
              Plain text
            </p>
            """
        )
    }

    @Test func testQuoteWithoutParagraphs() {
        let postText = PostText(html: "<blockquote>Quote</blockquote>")

        #expect(
            postText.toHTML() == """
            <blockquote>
              <p>
                Quote
              </p>
            </blockquote>
            """
        )
    }

    @Test func testNonBreakingSpace() {
        let postText = PostText(
            html: """
            <p>
            &nbsp;&nbsp;▲
            <br/>
            ▲&nbsp;▲
            <br/>
            . &nbsp; &nbsp; .&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;.
            </p>
            """
        )

        #expect(
            postText.toHTML() == """
            <p>
              &nbsp;&nbsp;▲
              <br/>
              ▲&nbsp;▲
              <br/>
              . &nbsp; &nbsp; .&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;.
            </p>
            """
        )
    }
}

extension PostText {
    func toHTML() -> String {
        return blocks.toHTML(level: 0)
    }
}

extension PostTextBlock {
    func toHTML(level: Int) -> String {
        switch self {
        case .paragraph(let content):
            return """
                \(indent(level))<p>
                \(indent(level + 1))\(content.toHTML(level: level + 1))
                \(indent(level))</p>
                """
        case .quote(let children):
            return """
                \(indent(level))<blockquote>
                \(children.toHTML(level: level + 1))
                \(indent(level))</blockquote>
                """
        case .codeBlock(let content):
            return "\(indent(level))<pre>\(content)</pre>"
        }
    }
}

private func indent(_ level: Int) -> String {
    return String(repeating: " ", count: level * 2)
}

extension Sequence where Element == PostTextInlineNode {
    func toHTML(level: Int) -> String {
        map { $0.toHTML(level: level) }.joined()
    }
}

extension Sequence where Element == PostTextBlock {
    func toHTML(level: Int) -> String {
        map { $0.toHTML(level: level) }.joined(separator: "\n")
    }
}

extension PostTextInlineNode {
    func toHTML(level: Int) -> String {
        switch self {
        case .text(let text):
            return Entities.escape(text)
                // Fixing a SwiftSoup bug https://github.com/scinfu/SwiftSoup/issues/313
                .replacingOccurrences(of: "\u{A0}", with: "&nbsp;")
        case .lineBreak:
            return "\n\(indent(level))<br/>\n\(indent(level))"
        case .code(let children):
            return "<code>\(children.toHTML(level: level))</code>"
        case .strong(let children):
            return "<b>\(children.toHTML(level: level))</b>"
        case .emphasis(let children):
            return "<i>\(children.toHTML(level: level))</i>"
        case .underline(let children):
            return "<u>\(children.toHTML(level: level))</u>"
        case .strikethrough(let children):
            return "<s>\(children.toHTML(level: level))</s>"
        case .subscript(let children):
            return "<sub>\(children.toHTML(level: level))</sub>"
        case .superscript(let children):
            return "<sup>\(children.toHTML(level: level))</sup>"
        case .link(let url, let children):
            return "<a href=\"\(url)\">\(children.toHTML(level: level))</a>"
        }
    }
}
