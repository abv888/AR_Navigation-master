import Foundation
import UIKit

extension CGPoint {
    func translated(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        return CGPoint(x: self.x + x, y: self.y + y)
    }
}
