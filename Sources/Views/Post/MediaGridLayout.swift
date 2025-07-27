import MediaGridLayout
import SwiftUI
import Placement

private let helper = MediaLayout(
    maxWidth: 1000,
    maxHeight: 1777, // 9:16
    minHeight: 475,  // ~2:1
    gap: 1.5,
)

private struct AspectRatio: HasAspectRatio {
    var aspectRatio: Double
}

private struct AspectRatioKey: PlacementLayoutValueKey {
    static let defaultValue: CGFloat? = nil
}

extension View {
    func aspectRatioForGridLayout(_ value: CGFloat?) -> some View {
        placementLayoutValue(key: AspectRatioKey.self, value: value)
    }
}

extension PlacementLayoutSubview {
    var aspectRatio: CGFloat {
        self[AspectRatioKey.self] ?? sizeThatFits(.unspecified).aspectRatio
    }
}

struct MediaGridLayout: PlacementLayout {
    var spacing: CGFloat

    var prefersLayoutProtocol: Bool {
        return true
    }

    struct Cache {
        private var result: MediaLayoutResult<AspectRatio>?

        @discardableResult
        fileprivate mutating func computeLayout(
            subviews: Subviews
        ) -> MediaLayoutResult<AspectRatio>? {
            if let result {
                return result
            }
            let result = helper.generate(
                subviews.map {
                    AspectRatio(aspectRatio: $0.aspectRatio)
                }
            )
            self.result = result
            return result
        }
    }

    func makeCache(subviews: Subviews) -> Cache {
        var cache = Cache()
        cache.computeLayout(subviews: subviews)
        return cache
    }

    private func fitInto(
        proposedSize: CGSize,
        actualAspectRatio: CGFloat
    ) -> CGSize {
        let proposedAspectRatio = proposedSize.width / proposedSize.height
        if proposedAspectRatio > actualAspectRatio {
            return CGSize(
                width: proposedSize.height * actualAspectRatio,
                height: proposedSize.height,
            )
        } else {
            return CGSize(
                width: proposedSize.width,
                height: proposedSize.width / actualAspectRatio,
            )
        }
    }

    func sizeThatFits(
        proposal: PlacementProposedViewSize,
        subviews: Subviews,
        cache: inout Cache,
    ) -> CGSize {
        if subviews.isEmpty || proposal.width == 0 || proposal.height == 0 {
            return .zero
        }
        if proposal == .infinity {
            return CGSize(width: CGFloat.infinity, height: CGFloat.infinity)
        }
        if subviews.count == 1 {
            var proposal = proposal
            let actualAspectRatio = subviews[0].aspectRatio
            if let proposedWidth = proposal.width, proposal.height == nil {
                proposal.height = proposedWidth / actualAspectRatio
            }
            if let proposedHeight = proposal.height, proposal.width == nil {
                proposal.width = proposedHeight * actualAspectRatio
            }
            return fitInto(
                proposedSize: subviews[0].sizeThatFits(proposal),
                actualAspectRatio: actualAspectRatio,
            )
        }
        let result = cache.computeLayout(subviews: subviews)!
        let idealSize = CGSize(width: result.width, height: result.height)
        return fitInto(
            proposedSize: proposal.replacingUnspecifiedDimensions(by: idealSize),
            actualAspectRatio: CGFloat(result.width) / CGFloat(result.height),
        )
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: PlacementProposedViewSize,
        subviews: Subviews,
        cache: inout Cache,
    ) {
        if subviews.isEmpty {
            return
        }
        if subviews.count == 1 {
            subviews[0]
                .place(
                    at: bounds.origin,
                    anchor: .topLeading,
                    proposal: .init(bounds.size),
                )
            return
        }

        let tilePlacement = cache
            .computeLayout(subviews: subviews)!
            .computeTilePlacement(bounds: bounds, gap: spacing)
            .enumerated()
            .map { (i, rect) in
                let size = subviews[i].sizeThatFits(.init(rect.size))
                return CGRect(origin: rect.origin, size: size)
            }

        for (i, subview) in subviews.enumerated() {
            let rect = tilePlacement[i]
            subview.place(
                at: CGPoint(x: rect.midX, y: rect.midY),
                anchor: .center,
                proposal: .init(width: rect.width, height: rect.height),
            )
        }
    }
}

extension MediaLayoutResult {
    fileprivate func computeTilePlacement(bounds: CGRect, gap: CGFloat) -> [CGRect] {
        var columnStarts: [CGFloat] = []
        columnStarts.reserveCapacity(columnSizes.count)
        var columnEnds: [CGFloat] = []
        columnEnds.reserveCapacity(columnSizes.count)
        var rowStarts: [CGFloat] = []
        rowStarts.reserveCapacity(rowSizes.count)
        var rowEnds: [CGFloat] = []
        rowEnds.reserveCapacity(rowSizes.count)
        var offset: CGFloat = bounds.minX
        for (i, colSize) in columnSizes.enumerated() {
            columnStarts.append(offset)
            let gapAdjustment = i == 0 || i == columnSizes.endIndex - 1 ? gap / 2 : gap
            offset += (CGFloat(colSize) / CGFloat(width) * bounds.width)
                .rounded() - gapAdjustment
            columnEnds.append(offset)
            offset += gap
        }
        offset = bounds.minY
        for (i, rowSize) in rowSizes.enumerated() {
            rowStarts.append(offset)
            let gapAdjustment = i == 0 || i == rowSizes.endIndex - 1 ? gap / 2 : gap
            offset += (CGFloat(rowSize) / CGFloat(height) * bounds.height)
                .rounded() - gapAdjustment
            rowEnds.append(offset)
            offset += gap
        }

        return tiles.map { tile in
            let x = columnStarts[tile.startCol]
            let y = rowStarts[tile.startRow]
            return CGRect(
                x: x,
                y: y,
                width: columnEnds[tile.startCol + tile.colSpan - 1] - x,
                height: rowEnds[tile.startRow + tile.rowSpan - 1] - y,
            )
        }
    }
}

@MainActor
internal func mediaGridPreviewHelper(
    _ resource: ImageResource,
    aspectRatio: CGFloat,
) -> some View {
    Color.clear
        .overlay {
            Image(resource)
                .resizable()
                .aspectRatio(contentMode: .fill)
        }
        .aspectRatioForGridLayout(aspectRatio)
        .clipped()
}

@available(iOS 17.0, *)
#Preview("Media grid: single item", traits: .sizeThatFitsLayout) {
    MediaGridLayout(spacing: 1) {
        Image(.birdPhoto)
            .resizable()
            .aspectRatio(contentMode: .fit)
    }
    .frame(maxWidth: 300)
}

#Preview("Media grid: single item inside list") {
    List {
        MediaGridLayout(spacing: 1) {
            mediaGridPreviewHelper(.birdPhoto, aspectRatio: 2047 / 1484)
        }
        .frame(maxHeight: 510)
    }
}

@available(iOS 17.0, *)
#Preview("Media grid: 2 square items", traits: .sizeThatFitsLayout) {
    MediaGridLayout(spacing: 1) {
        Group {
            Image(.rootsPhoto).resizable()
            Image(.lakePhoto).resizable()
        }
        .aspectRatio(contentMode: .fit)
    }
    .frame(maxWidth: 300)
}

@available(iOS 17.0, *)
#Preview("Media grid: 2 items, one above the other", traits: .sizeThatFitsLayout) {
    MediaGridLayout(spacing: 1) {
        mediaGridPreviewHelper(.birdPhoto, aspectRatio: 2047 / 1484)
        mediaGridPreviewHelper(.birdPhoto, aspectRatio: 2047 / 1484)
    }
}

@available(iOS 17.0, *)
#Preview("Media grid: 3 items, one above two smaller ones", traits: .sizeThatFitsLayout) {
    MediaGridLayout(spacing: 1) {
        Image(.rootsPhoto).resizable()
        Image(.lakePhoto).resizable()
        Image(.lakePhoto).resizable()
    }
}

@available(iOS 17.0, *)
#Preview("Media grid: 4 items, one above three smaller ones", traits: .sizeThatFitsLayout) {
    MediaGridLayout(spacing: 1) {
        Image(.rootsPhoto).resizable()
        Image(.lakePhoto).resizable()
        Image(.rootsPhoto).resizable()
        Image(.lakePhoto).resizable()
    }
}
