import Foundation
import UIKit

protocol Reusable: AnyObject {
    static var reuseIdentifier: String { get }
    static var nibName: String { get }
    
    func specific<T>() -> T?
}

extension Reusable {
    static var reuseIdentifier: String { get { return String(describing: Self.self) } }
    static var nibName: String { get { return String(describing: Self.self) } }
    
    func specific<T>() -> T? {
        return self as? T
    }
}
