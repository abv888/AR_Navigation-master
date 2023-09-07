import Foundation
import UIKit

protocol Router: AnyObject {
    associatedtype ModuleView: View
    static func moduleInput<T>() throws -> T
}

enum RouterError: Error {
    case wrongView
}
