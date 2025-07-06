import SwiftUI

struct ColorSchemeCustomizer: View {
    @EnvironmentObject private var paletteHolder: PaletteHolder
    @State private var hueAdder: Double = 211
    @State private var chromaMultiplier: Double = 1.5

    private func updatePalette() {
        paletteHolder.palette = Palette.vk.mapColors(name: "Customized") {
            $0.h += hueAdder
            $0.c *= chromaMultiplier
        }
    }

    var body: some View {
        List {
            Section("Hue: \(hueAdder)") {
                Slider(value: $hueAdder, in: 0...360)
            }
            Section("Chroma: \(chromaMultiplier)") {
                Slider(value: $chromaMultiplier, in: -10...10)
            }
        }
        .frame(maxHeight: 200)
        .onChangePolyfill(of: hueAdder, updatePalette)
        .onChangePolyfill(of: chromaMultiplier, updatePalette)
    }
}
