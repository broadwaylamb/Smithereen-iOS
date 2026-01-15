import SwiftUI

struct ProfileCountersView: View {
    var counters: [ProfileCounter]

    @EnvironmentObject private var palette: PaletteHolder

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Spacer(minLength: 0)
                ForEach(counters.indexed(), id: \.offset) { (i, counter) in
                    if counter.value > 0 {
                        VStack {
                            Text(verbatim: formatCounter(counter.value))
                                .font(.title2)
                                .fontWeight(.medium)
                                .foregroundStyle(palette.profileCounterNumber)
                            Text(counter.text)
                                .foregroundStyle(palette.grayText)
                        }
                        .padding(.horizontal, 6)
                    }
                }
                Spacer(minLength: 0).layoutPriority(1)
            }
        }
        // Fixing an iOS 16 bug when ScrollView nested inside a refreshable List
        // becomes itself refreshable.
        .environment(\EnvironmentValues.refresh as! WritableKeyPath<_, _>, nil)
    }
}

struct ProfileCounter {
    var value: Int
    fileprivate var text: LocalizedStringKey

    init(value: Int?, text: (Int) -> LocalizedStringKey) {
        self.value = value ?? 0

        // Values above 1000 will use abbreviated notation
        // like 1.2K or 2M.
        // We want to always use the plural form with
        // such values, so we pass 1000 for them for selecting
        // the right localization key.
        self.text = text(min(self.value, 1000))
    }
}

private func formatCounter(_ n: Int) -> String {
    // We want to use locale-specific decimal separators,
    // but always use the abbreviations from the English locale, like 12K, 3M.
    // For this reason, just using `.number.notation(.compactName)` is not enough,
    // because e.g. for the Russian locale it will produce "12 тыс." instead of "12K".
    //
    // But at the same time we can't hardcode the en_US locale, because it will use
    // the US-specific decimal separator, which we don't want.
    let scale: Double
    let abbreviation: String
    let abs = abs(n)
    let canBeFractional: Bool
    switch abs {
    case 0..<1000:
        scale = 1
        abbreviation = ""
        canBeFractional = false
    case 1000..<1_000_000:
        scale = 0.001
        abbreviation = "K"
        canBeFractional = abs < 10_000
    case 1_000_000..<1_000_000_000:
        scale = 0.000_001
        abbreviation = "M"
        canBeFractional = abs < 10_000_000
    default:
        scale = 0.000_000_001
        abbreviation = "B"
        canBeFractional = abs < 10_000_000_000
    }

    return n.formatted(
        .number
            .scale(scale)
            .precision(.fractionLength(canBeFractional ? 0...1 : 0...0))
    ) + abbreviation
}

@available(iOS 17.0, *)
#Preview(traits: .sizeThatFitsLayout) {
    ProfileCountersView(
        counters: [
            ProfileCounter(value: 2) { "\($0) friends" },
            ProfileCounter(value: 5) { "\($0) in common" },
            ProfileCounter(value: 21) { "\($0) followers" },
            ProfileCounter(value: 1) { "\($0) groups" },
            ProfileCounter(value: 129) { "\($0) photos" },
            ProfileCounter(value: 1) { "\($0) videos" },
            ProfileCounter(value: 1531) { "\($0) audios" },
        ]
    )
    .environmentObject(PaletteHolder())
}
