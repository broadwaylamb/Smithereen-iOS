import SwiftUI

struct ProfileCountersView: View {
    var counters: [ProfileCounter]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 9) {
                ForEach(counters.indexed(), id: \.offset) { (i, counter) in
                    if counter.value > 0 {
                        VStack {
                            Text("\(counter.value)")
                                .font(.title2)
                                .fontWeight(.medium)
                            Text(counter.text)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 6)
                    }
                }
            }
        }
    }
}

struct ProfileCounter {
    var value: Int
    fileprivate var text: LocalizedStringKey

    init(value: Int, text: (Int) -> LocalizedStringKey) {
        self.value = value
        self.text = text(value)
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
}
