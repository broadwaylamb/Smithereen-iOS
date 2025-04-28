import SwiftUI

private struct OnChangePolyfillViewModifier<Value: Equatable>: ViewModifier {

	let value: Value
	let action: () -> Void

	private let helper = Helper()

	private class Helper {
		private var oldValue: Value?
		func update(_ newValue: Value) -> Bool {
			if newValue == oldValue {
				return false
			} else {
				oldValue = newValue
				return true
			}
		}
	}

	func body(content: Content) -> Content {
		if helper.update(value) {
			DispatchQueue.main.async {
				self.action()
			}
		}
		return content
	}
}

private struct LeadingInsetListSeparatorViewModifier: ViewModifier {
    var leadingInset: CGFloat
    func body(content: Content) -> some View {
        ZStack(alignment: .topLeading) {
            // Separator is aligned at the first text block
            Text(verbatim: "asd")
                .offset(x: leadingInset)
            content
        }
    }
}

extension View {
	func onChangePolyfill<V: Equatable>(
		of value: V,
		initial: Bool = false,
		_ action: @escaping () -> Void
	) -> some View {
		if #available(iOS 17.0, *) {
			return onChange(of: value, action)
		} else {
			return modifier(OnChangePolyfillViewModifier(value: value, action: action))
		}
	}

	func navigationBarBackground(_ color: Color) -> some View {
		if #available(iOS 16.0, *) {
			return toolbarBackground(color, for: .navigationBar)
				.toolbarBackground(.visible, for: .navigationBar)
				.toolbarColorScheme(.dark, for: .navigationBar)
		} else {
			// https://developer.apple.com/documentation/technotes/tn3106-customizing-uinavigationbar-appearance
			let newNavBarAppearance = UINavigationBarAppearance()
			newNavBarAppearance.configureWithOpaqueBackground()
			newNavBarAppearance.backgroundColor = UIColor(color)

			// Apply white colored normal and large titles.
			newNavBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
			newNavBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]


			// Apply white color to all the nav bar buttons.
			let barButtonItemAppearance = UIBarButtonItemAppearance(style: .plain)
			barButtonItemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.white]
			barButtonItemAppearance.disabled.titleTextAttributes = [.foregroundColor: UIColor.lightText]
			barButtonItemAppearance.highlighted.titleTextAttributes = [.foregroundColor: UIColor.label]
			barButtonItemAppearance.focused.titleTextAttributes = [.foregroundColor: UIColor.white]
			newNavBarAppearance.buttonAppearance = barButtonItemAppearance
			newNavBarAppearance.backButtonAppearance = barButtonItemAppearance
			newNavBarAppearance.doneButtonAppearance = barButtonItemAppearance


			let appearance = UINavigationBar.appearance()
			appearance.scrollEdgeAppearance = newNavBarAppearance
			appearance.compactAppearance = newNavBarAppearance
			appearance.standardAppearance = newNavBarAppearance
			appearance.compactScrollEdgeAppearance = newNavBarAppearance
			return self
		}
	}

    func listSeparatorLeadingInset(_ leadingInset: CGFloat) -> some View {
        // Starting from iOS 16 list row separators in SwiftUI are aligned by default
        // to the leading text in the row, if text is present.
        // It's different from the iOS 15 behavior, where the insets of the separator
        // don't adjust to the content of the row.
        if #available(iOS 16.0, *) {
            return alignmentGuide(.listRowSeparatorLeading) { _ in leadingInset }
        }
        return self
    }
}
