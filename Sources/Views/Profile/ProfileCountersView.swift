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
                            Text("\(counter.value)")
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
        self.text = text(self.value)
    }
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
