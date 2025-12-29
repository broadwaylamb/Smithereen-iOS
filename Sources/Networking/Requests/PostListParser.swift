import Foundation
import SwiftSoup
import SmithereenAPI

private let blurHashRegex =
    try! NSRegularExpression(pattern: #"background-color: #([a-fA-F0-9]{6})"#)

func parsePicture(_ element: Element) -> PictureFromHTML {
    do {
        let img = try element.select("img").first()
        let altText = try img?.attr("alt")
        let style = try img?.attr("style")
        let blurHash = style.flatMap {
            blurHashRegex.firstMatch(in: $0, captureGroup: 1)
        }?.flatMap(RGBAColor.init(cssHex:))
        for resource in try element.select("source") {
            if try resource.attr("type") != "image/webp" {
                continue
            }
            let srcsets = try resource.attr("srcset")
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }

            for srcset in srcsets {
                if srcset.hasSuffix(" 2x") {
                    let url = URL(string: String(srcset.prefix(srcset.count - 3)))
                    return PictureFromHTML(url: url, altText: altText, blurHash: blurHash)
                }
            }
        }
    } catch {
        // If there is an error, we ignore it and return nil
    }
    return PictureFromHTML()
}

private func parseSinglePhoto(_ link: Element) -> PhotoAttachment? {
    let dataPv = try? Data(link.attr(Array("data-pv".utf8)))
    let sizes = dataPv.flatMap {
        try? JSONDecoder().decode(PhotoViewerInlineData.self, from: $0)
    }
    return PhotoAttachment(
        sizes: sizes?.urls ?? [],
    )
}

private func parsePostAttachments(
    _ postAttachments: Element?
) throws -> [PostAttachment] {
    guard let postAttachments, postAttachments.hasClass("postAttachments") else {
        return []
    }
    let photos = try postAttachments
        .select("a.photo")
        .compactMap { parseSinglePhoto($0).map(PostAttachment.photo) }
    return photos
}
