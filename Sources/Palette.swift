import SwiftUI

struct Palette {
    var name: String
    @RGBAColor var accent: Color
    @RGBAColor var feedBackground: Color
    @RGBAColor var loadingImagePlaceholder: Color

    @RGBAColor var postFooterSeparator: Color
    @RGBAColor var compactPostButtonTint: Color
    @RGBAColor var compactPostButtonHighlightedTint: Color
    @RGBAColor var regularPostCommentButton: Color
    @RGBAColor var regularPostLikeAndRepostButton: Color
    @RGBAColor var regularPostLikeText: Color

    @RGBAColor var repostVerticalLine: Color
    @RGBAColor var repostIcon: Color

    @RGBAColor var postCodeBlockBackground: Color

    struct SideMenuPalette: Hashable {
        @RGBAColor var background: Color
        @RGBAColor var selectedBackground: Color
        @RGBAColor var icon: Color
        @RGBAColor var separator: Color
        @RGBAColor var text: Color
    }

    var sideMenu: SideMenuPalette

    static let vk: Palette = .init(
        name: "VK",
        accent: #colorLiteral(red: 0.3397949338, green: 0.5224637985, blue: 0.718362391, alpha: 1),
        feedBackground: #colorLiteral(red: 0.9254901961, green: 0.9333333333, blue: 0.9529411765, alpha: 1),
        loadingImagePlaceholder: #colorLiteral(red: 0.9420066476, green: 0.9368781447, blue: 0.9587077498, alpha: 1),
        postFooterSeparator: #colorLiteral(red: 0.8031623363, green: 0.8078625798, blue: 0.8165373206, alpha: 1),
        compactPostButtonTint: #colorLiteral(red: 0.6374332905, green: 0.6473867297, blue: 0.6686993241, alpha: 1),
        compactPostButtonHighlightedTint: #colorLiteral(red: 0.1697994363, green: 0.371793279, blue: 0.6778445559, alpha: 1),
        regularPostCommentButton: #colorLiteral(red: 0.5647058824, green: 0.5764705882, blue: 0.5803921569, alpha: 1),
        regularPostLikeAndRepostButton: #colorLiteral(red: 0.3568627451, green: 0.4862745098, blue: 0.6823529412, alpha: 1),
        regularPostLikeText: #colorLiteral(red: 0.5098039216, green: 0.6235294118, blue: 0.7843137255, alpha: 1),
        repostVerticalLine: #colorLiteral(red: 0.8352941176, green: 0.8470588235, blue: 0.8549019608, alpha: 1),
        repostIcon: #colorLiteral(red: 0.5768606067, green: 0.6835266352, blue: 0.7990577817, alpha: 1),
        postCodeBlockBackground: #colorLiteral(red: 0.9348388314, green: 0.9348388314, blue: 0.9348388314, alpha: 1),
        sideMenu: .init(
            background: #colorLiteral(red: 0.2235294118, green: 0.2705882353, blue: 0.3215686275, alpha: 1),
            selectedBackground: #colorLiteral(red: 0.1882352941, green: 0.2235294118, blue: 0.2705882353, alpha: 1),
            icon: #colorLiteral(red: 0.6705882353, green: 0.7098039216, blue: 0.7607843137, alpha: 1),
            separator: #colorLiteral(red: 0.2862745098, green: 0.3294117647, blue: 0.3843137255, alpha: 1),
            text: #colorLiteral(red: 0.9058823529, green: 0.9176470588, blue: 0.9450980392, alpha: 1),
        ),
    )

    static let smithereen: Palette = Palette.vk.mapColors(name: "Smithereen") {
        $0.h += 211
        $0.c *= 1.5
    }

    func mapColors(name: String, _ transform: (inout LCHColor) -> Void) -> Palette {
        func map(_ color: RGBAColor) -> RGBAColor {
            var lch = color.toLCH()
            transform(&lch)
            return lch.toRGB()
        }
        return .init(
            name: name,
            accent: map($accent),
            feedBackground: map($feedBackground),
            loadingImagePlaceholder: map($loadingImagePlaceholder),
            postFooterSeparator: map($postFooterSeparator),
            compactPostButtonTint: map($compactPostButtonTint),
            compactPostButtonHighlightedTint: map($compactPostButtonHighlightedTint),
            regularPostCommentButton: map($regularPostCommentButton),
            regularPostLikeAndRepostButton: map($regularPostLikeAndRepostButton),
            regularPostLikeText: map($regularPostLikeText),
            repostVerticalLine: map($repostVerticalLine),
            repostIcon: map($repostIcon),
            postCodeBlockBackground: map($postCodeBlockBackground),
            sideMenu: .init(
                background: map(sideMenu.$background),
                selectedBackground: map(sideMenu.$selectedBackground),
                icon: map(sideMenu.$icon),
                separator: map(sideMenu.$separator),
                text: map(sideMenu.$text)
            ),
        )
    }
}

extension Palette: Equatable {
    static func ==(lhs: Palette, rhs: Palette) -> Bool {
        lhs.name == rhs.name
    }
}

extension Palette: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}

@dynamicMemberLookup
final class PaletteHolder: ObservableObject {
    private let userDefaults: UserDefaults

    private static let userDefaultsKey = Bundle.main.bundleIdentifier! + ".palette"

    @Published var palette: Palette = .smithereen {
        didSet {
            userDefaults.set(palette.name, forKey: Self.userDefaultsKey)
        }
    }

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        if let preferredPalette = (userDefaults
            .value(forKey: Self.userDefaultsKey) as? String)
            .flatMap(Palette.init)
        {
            self.palette = preferredPalette
        }
    }

    subscript<T>(dynamicMember keyPath: KeyPath<Palette, T>) -> T {
        palette[keyPath: keyPath]
    }
}

extension Palette: Identifiable {
    var id: String {
        name
    }
}

extension Palette: RawRepresentable {
    var rawValue: String {
        name
    }

    init?(rawValue: String) {
        guard let palette = Palette.allCases.first(where: { $0.name == rawValue }) else {
            return nil
        }
        self = palette
    }
}

extension Palette: CaseIterable {
    static let allCases: [Palette] = [.smithereen, .vk]
}
