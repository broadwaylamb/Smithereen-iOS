struct Indexed<Element> {
  let index: Int
  let value: Element
}

extension Indexed: Equatable where Element: Equatable {}
extension Indexed: Hashable where Element: Hashable {}

extension Indexed: Identifiable {
    var id: Int { index }
}

extension Sequence {
  func indexed() -> [Indexed<Element>] {
      return enumerated().map(Indexed.init)
  }
}
