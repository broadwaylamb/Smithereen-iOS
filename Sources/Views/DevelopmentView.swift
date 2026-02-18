import SwiftUI
import SmithereenAPI

struct DevelopmentView: View {
    var api: APIService

    @EnvironmentObject private var paletteHolder: PaletteHolder
    @EnvironmentObject private var errorObserver: ErrorObserver

    @State private var hueAdder: Double = 211
    @State private var chromaMultiplier: Double = 1.5

    private func updatePalette(hueAdder: Double, chromaMultiplier: Double) {
        paletteHolder.palette = Palette.vk.mapColors(name: "Customized") {
            $0.h += hueAdder
            $0.c *= chromaMultiplier
        }
    }

    var body: some View {
        List {
            Section("API") {
                Button("Test Captcha") {
                    Task {
                        await errorObserver.runCatching {
                            try await api.invokeMethod(Utils.TestCaptcha())
                        }
                    }
                }
            }
            Section("Color theme") {
                HStack {
                    Text("Hue: \(hueAdder, format: .number.precision(.fractionLength(1)))")
                        .frame(width: 150, alignment: .leading)
                    Slider(value: $hueAdder, in: 0...360)
                }
                HStack {
                    Text("Chroma: \(chromaMultiplier, format: .number.precision(.fractionLength(3)))")
                        .frame(width: 150, alignment: .leading)
                    Slider(value: $chromaMultiplier, in: -10...10)
                }
            }
        }
        .listStyle(.grouped)
        .colorScheme(.light)
        .onChange(of: hueAdder) {
            updatePalette(hueAdder: $0, chromaMultiplier: chromaMultiplier)
        }
        .onChange(of: chromaMultiplier) {
            updatePalette(hueAdder: hueAdder, chromaMultiplier: $0)
        }
    }
}

#Preview("Development") {
    DevelopmentView(api: MockApi())
        .environmentObject(PaletteHolder())
        .environmentObject(ErrorObserver())
}
