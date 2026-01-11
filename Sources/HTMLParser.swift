import libxml2

// XMLParser from Foundation doesn't handle HTML entities, so we use our own libxml2
// wrapper.

protocol HTMLParserDelegate: AnyObject {
    func startElement(_ tagName: String, attributes: [String : String])
    func endElement(_ tagName: String)
    func foundCharacters(_ text: String)
}

struct HTMLParser {
    var options: Options = []

    struct Options: OptionSet {
        var rawValue: htmlParserOption.RawValue
        init(rawValue: htmlParserOption.RawValue) {
            self.rawValue = rawValue
        }

        static let noBlanks = Self(rawValue: HTML_PARSE_NOBLANKS.rawValue)
    }

    func parse(_ html: String, delegate: any HTMLParserDelegate) {
        guard let context = htmlNewParserCtxt() else {
            fatalError("Could not allocate HTML parser context")
        }
        defer {
            context.pointee.sax = nil
            htmlFreeParserCtxt(context)
        }
        htmlCtxtUseOptions(context, Int32(options.rawValue))
        context.pointee.userData = Unmanaged
            .passUnretained(delegate as AnyObject)
            .toOpaque()

        var handler = xmlSAXHandler()

        handler.startElement = { ctx, name, attrs in
            guard let ctx, let name else { return }

            var attributes = [String : String]()
            if var attrs = attrs {
                while let attr = attrs.pointee {
                    guard let value = attrs.advanced(by: 1).pointee else { break }
                    attributes[String(cString: attr)] = String(cString: value)
                    attrs = attrs.advanced(by: 2)
                }
            }

            delegateFromCtx(ctx)
                .startElement(String(cString: name), attributes: attributes)
        }

        handler.endElement = { ctx, name in
            guard let ctx, let name else { return }
            delegateFromCtx(ctx).endElement(String(cString: name))
        }

        handler.characters = { ctx, characters, len in
            guard let ctx, let characters else { return }
            let buffer = UnsafeBufferPointer(start: characters, count: Int(len))
            delegateFromCtx(ctx).foundCharacters(String(decoding: buffer, as: UTF8.self))
        }

        html.withCString { cString in
            withUnsafeMutablePointer(to: &handler) { handlerPtr in
                context.pointee.sax = handlerPtr

                _ = htmlCtxtReadDoc(context, cString, nil, nil, 0)
            }
        }
    }
}

private func delegateFromCtx(
    _ context: UnsafeMutableRawPointer
) -> any HTMLParserDelegate {
    Unmanaged<AnyObject>.fromOpaque(context).takeUnretainedValue() as! HTMLParserDelegate
}
