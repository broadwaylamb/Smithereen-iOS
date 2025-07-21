import MediaGridLayout
import SwiftUI

struct MediaGridView<Elements: Collection, Content: View>: View
    where Elements.Element: HasAspectRatio
{
    var elements: Elements
    var content: (Elements.Element) -> Content
    var layout: MediaLayout

    init(
        elements: Elements,
        maxWidth: Double,
        maxHeight: Double,
        minHeight: Double,
        gap: Double,
        @ViewBuilder content: @escaping (Elements.Element) -> Content,
    ) {
        self.elements = elements
        self.content = content
        self.layout = MediaLayout(
            maxWidth: maxWidth,
            maxHeight: maxHeight,
            minHeight: minHeight,
            gap: gap,
        )
    }

    var body: some View {
        switch elements.count {
        case 0:
            EmptyView()
        case 1:
            let element = elements.first!
            content(element)
                .aspectRatio(element.aspectRatio, contentMode: .fit)
                .frame(
                    maxWidth: layout.maxWidth,
                    minHeight: layout.minHeight,
                    maxHeight: layout.maxHeight,
                )
        default:
            let result = layout.generate(elements)!
            let tiles = result.prepareTiles(gap: layout.gap)
            ZStack(alignment: .topLeading) {
                ForEach(tiles.indexed(), id: \.offset) { (_, tile) in
                    content(tile.element)
                        .clipped()
                        .offset(x: tile.rect.minX, y: tile.rect.minY)
                        .frame(width: tile.rect.width, height: tile.rect.height)
                }
            }
            .frame(
                width: CGFloat(result.width),
                height: CGFloat(result.height),
                alignment: .topLeading,
            )
        }
    }
}

fileprivate struct TileWithCoordinates<Element> {
    var rect: CGRect
    var element: Element
}

extension MediaLayoutResult {
    fileprivate func prepareTiles(gap: CGFloat) -> [TileWithCoordinates<Element>] {
        var columnStarts: [CGFloat] = []
        columnStarts.reserveCapacity(columnSizes.count)
        var columnEnds: [CGFloat] = []
        columnEnds.reserveCapacity(columnSizes.count)
        var rowStarts: [CGFloat] = []
        rowStarts.reserveCapacity(rowSizes.count)
        var rowEnds: [CGFloat] = []
        rowEnds.reserveCapacity(rowSizes.count)
        var offset: CGFloat = 0
        for (i, colSize) in columnSizes.enumerated() {
            columnStarts.append(offset)
            let gapAdjustment = i == 0 || i == columnSizes.endIndex - 1 ? gap / 2 : gap
            offset += CGFloat(colSize) - gapAdjustment
            columnEnds.append(offset)
            offset += gap
        }
        offset = 0
        for (i, rowSize) in rowSizes.enumerated() {
            rowStarts.append(offset)
            let gapAdjustment = i == 0 || i == rowSizes.endIndex - 1 ? gap / 2 : gap
            offset += CGFloat(rowSize) - gapAdjustment
            rowEnds.append(offset)
            offset += gap
        }

        return tiles.map { tile in
            let x = columnStarts[tile.startCol]
            let y = rowStarts[tile.startRow]
            let rect = CGRect(
                x: x,
                y: y,
                width: columnEnds[tile.startCol + tile.colSpan - 1] - x,
                height: rowEnds[tile.startRow + tile.rowSpan - 1] - y,
            )
            return TileWithCoordinates(rect: rect, element: tile.element)
        }
    }
}

private struct TestView: View {
    var color: Color
    var width: Double
    var height: Double

    var body: some View {
        GeometryReader { proxy in
            color
                .aspectRatio(aspectRatio, contentMode: .fill)
                .overlay {
                    Text(verbatim: "\(Int(proxy.size.width))×\(Int(proxy.size.height))")
                }
        }
    }
}

extension TestView: @preconcurrency HasAspectRatio {
    var aspectRatio: Double { width / height }
}

@available(iOS 17.0, *)
#Preview("Media grid: single item", traits: .sizeThatFitsLayout) {
    MediaGridView(
        elements: [TestView(color: .red, width: 20, height: 100)],
        maxWidth: 320,
        maxHeight: 569,
        minHeight: 160,
        gap: 1,
        content: { $0 },
    )
}

@available(iOS 17.0, *)
#Preview("Media grid: 2 square items", traits: .sizeThatFitsLayout) {
    MediaGridView(
        elements: [
            TestView(color: .red, width: 20, height: 20),
            TestView(color: .yellow, width: 20, height: 20),
        ],
        maxWidth: 320,
        maxHeight: 569,
        minHeight: 160,
        gap: 1,
        content: { $0 },
    )
}

@available(iOS 17.0, *)
#Preview("Media grid: 2 items, one above the other", traits: .sizeThatFitsLayout) {
    MediaGridView(
        elements: [
            TestView(color: .red, width: 640, height: 492),
            TestView(color: .yellow, width: 640, height: 324),
        ],
        maxWidth: 320,
        maxHeight: 569,
        minHeight: 160,
        gap: 1,
        content: { $0 },
    )
}

@available(iOS 17.0, *)
#Preview(
    "Media grid: 3 items, one on the left, two on the right",
    traits: .sizeThatFitsLayout,
) {
    MediaGridView(
        elements: [
            TestView(color: .yellow, width: 25, height: 40),
            TestView(color: .red, width: 15, height: 20),
            TestView(color: .green, width: 15, height: 20),
        ],
        maxWidth: 320,
        maxHeight: 569,
        minHeight: 160,
        gap: 1,
        content: { $0 },
    )
}


@available(iOS 17.0, *)
#Preview("Media grid: 3 items, one above two smaller ones", traits: .sizeThatFitsLayout) {
    MediaGridView(
        elements: [
            TestView(color: .yellow, width: 60, height: 20),
            TestView(color: .blue, width: 30, height: 20),
            TestView(color: .green, width: 20, height: 20),
        ],
        maxWidth: 320,
        maxHeight: 569,
        minHeight: 160,
        gap: 1,
        content: { $0 },
    )
}

@available(iOS 17.0, *)
#Preview(
    "Media grid: 4 items, one above three smaller ones",
    traits: .sizeThatFitsLayout
) {
    MediaGridView(
        elements: [
            TestView(color: .yellow, width: 640, height: 578),
            TestView(color: .blue, width: 600, height: 540),
            TestView(color: .green, width: 640, height: 623),
            TestView(color: .orange, width: 480, height: 640),
        ],
        maxWidth: 320,
        maxHeight: 569,
        minHeight: 160,
        gap: 1,
        content: { $0 },
    )
}

