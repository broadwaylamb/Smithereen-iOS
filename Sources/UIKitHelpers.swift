import UIKit

extension UIView {
    func sizeThatFits(width: CGFloat) -> CGSize {
        sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
    }
}
