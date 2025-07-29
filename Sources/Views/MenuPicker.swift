import SwiftUI

/// A replacement for SwiftUI's Picker, because the latter behaves weirdly in lists on iOS 15
struct MenuPicker<SelectionValue: Hashable, Content: View>: View {
    private var title: LocalizedStringKey
    private var selection: Binding<SelectionValue>
    private var content: () -> Content

    init(
        _ title: LocalizedStringKey,
        selection: Binding<SelectionValue>,
        @ViewBuilder content: @escaping () -> Content,
    ) {
        self.title = title
        self.selection = selection
        self.content = content
    }
    

    var body: some View {
        if #available(iOS 16, *) {
            Picker(title, selection: selection, content: content)
                .pickerStyle(.menu)
        } else {
            HStack {
                Text(title)
                Spacer()
                Picker(selection: selection, content: content, label: { EmptyView() })
                    .pickerStyle(.menu)
            }
            .accessibilityAddTraits(.isButton)
        }
    }
}
