import Testing

@testable import Smithereen

struct RichTextParsingTests {
    @Test func testBlocks() {
        let postText = RichText(
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
        let postText = RichText(
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
        let postText = RichText(
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
        let postText = RichText(
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
        let postText = RichText(
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
        let postText = RichText(html: "Plain text")

        #expect(
            postText.toHTML() == """
            <p>
              Plain text
            </p>
            """
        )
    }

    @Test func testQuoteWithoutParagraphs() {
        let postText = RichText(html: "<blockquote>Quote</blockquote>")

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
        let postText = RichText(
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

    @Test func testMention() {
        let postText = RichText(
            html: """
            <p>
            <a href="https://smithereen.local/users/1" class="mention" data-user-id="1">Hello!</a>
            </p>
            """
        )
        #expect(
            postText.toHTML() == """
            <p>
              <a href="https://smithereen.local/users/1" class="mention" data-user-id="1">Hello!</a> 
            </p>
            """
        )
    }
}

extension RichText {
    func toHTML() -> String {
        return blocks.toHTML(level: 0)
    }
}

extension RichText.Block {
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

extension Sequence where Element == RichText.InlineNode {
    func toHTML(level: Int) -> String {
        map { $0.toHTML(level: level) }.joined()
    }
}

extension Sequence where Element == RichText.Block {
    func toHTML(level: Int) -> String {
        map { $0.toHTML(level: level) }.joined(separator: "\n")
    }
}

extension RichText.InlineNode {
    func toHTML(level: Int) -> String {
        switch self {
        case .text(let text):
            return text.replacingOccurrences(of: "\u{A0}", with: "&nbsp;")
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
        case .link(let url, let mentionedActorID, let children):
            let mentionAttrs = if let mentionedActorID {
                #" class="mention" data-user-id="\#(mentionedActorID)""#
            } else {
                ""
            }
            return "<a href=\"\(url)\"\(mentionAttrs)>\(children.toHTML(level: level))</a>"
        }
    }
}
