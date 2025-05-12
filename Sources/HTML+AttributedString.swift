import Foundation
import SwiftUI
import SwiftSoup

func renderHTML(_ html: Element) -> AttributedString {
    let renderer = HtmlRenderer()

    // The renderer itself doesn't throw, so it's safe to force-try.
    try! html.traverse(renderer)

    return renderer.result
}

func renderHTML(_ htmlString: String) -> AttributedString {
    do {
        let html = try SwiftSoup.parse(htmlString)
        return renderHTML(html)
    } catch {
        return AttributedString(htmlString)
    }
}

private class HtmlRenderer: NodeVisitor {
    var result = AttributedString()
    private var attributesStack: [AttributeContainer] = [AttributeContainer().font(.body)]
    private var presentationIntentCounter = 1
    private var isFirstParagraph: Bool = true
    private var codeBlockDepth = 0
    private var lastWasWhite = false
    private var stripLeading = true

    func head(_ node: Node, _ depth: Int) throws {
        var newContainer = attributesStack.last ?? AttributeContainer()
        if let textNode = node as? TextNode {
            let text = textNode.getWholeText()
            result.append(AttributedString(codeBlockDepth > 0 ? text : normalisedWhitespace(text), attributes: newContainer))
        } else if let element = node as? Element {
            // The server should only use the tags mention here:
            // https://github.com/grishka/Smithereen/blob/c530e8b8fcb8145b8e78de142710736e6bf46c3c/src/main/java/smithereen/text/MicroFormatAwareHTMLWhitelist.java#L27
            // If it sends other tags, we ignore them.
            switch element.tagNameNormal() {
            case "a":
                let href = try element.attr("href")
                if !href.isEmpty {
                    newContainer.link = URL(string: href)
                }
            case "b":
                newContainer.inlinePresentationIntent.insert(.stronglyEmphasized)
            case "i":
                newContainer.inlinePresentationIntent.insert(.emphasized)
            case "u":
                newContainer.underlineStyle = .single
            case "s":
                newContainer.inlinePresentationIntent.insert(.strikethrough)
            case "code":
                newContainer.inlinePresentationIntent.insert(.code)
            case "p":
                addParagraphBreakIfNeeded(&newContainer)
                addPresentationIntent(.paragraph, to: &newContainer)
            case "blockquote":
                // TODO: Formatting
                addParagraphBreakIfNeeded(&newContainer)
                addPresentationIntent(.blockQuote, to: &newContainer)
            case "span":
                break
            case "sub":
                break // TODO
            case "sup":
                break // TODO
            case "br":
                stripLeading = true
                newContainer.inlinePresentationIntent.insert(.softBreak)
                result.append(AttributedString("\n", attributes: newContainer))
            case "pre":
                if codeBlockDepth == 0 {
                    addParagraphBreakIfNeeded(&newContainer)
                }
                codeBlockDepth += 1
                newContainer.inlinePresentationIntent.insert(.code)
                addPresentationIntent(.codeBlock(languageHint: nil), to: &newContainer)
            default:
                break
            }
        }
        attributesStack.append(newContainer)
    }

    func tail(_ node: Node, _ depth: Int) throws {
        attributesStack.removeLast()
        if let element = node as? Element, element.tagNameNormal() == "pre" {
            codeBlockDepth -= 1
        }
    }

    private func addParagraphBreakIfNeeded(_ container: inout AttributeContainer) {
        if isFirstParagraph {
            isFirstParagraph = false
        } else {
            result.append(AttributedString("\n\r", attributes: container))
        }
        stripLeading = true
    }

    private func addPresentationIntent(_ intentKind: PresentationIntent.Kind, to container: inout AttributeContainer) {
        container.presentationIntent = PresentationIntent(intentKind, identity: presentationIntentCounter, parent: container.presentationIntent)
        presentationIntentCounter += 1
    }

    private func normalisedWhitespace(_ string: String) -> String {
        var accum = String()
        var reachedNonWhite: Bool = false

        for c in string {
            if (c.isWhitespace) {
                if (stripLeading && !reachedNonWhite) || lastWasWhite {
                    continue
                }
                accum.append(" ")
                lastWasWhite = true
            } else {
                accum.append(c)
                lastWasWhite = false
                reachedNonWhite = true
            }
        }
        return accum
    }

}

private extension Optional where Wrapped: OptionSet, Wrapped.Element == Wrapped {
    mutating func insert(_ newValue: Wrapped) {
        var existing = self ?? []
        existing.insert(newValue)
        self = .some(existing)
    }
}
