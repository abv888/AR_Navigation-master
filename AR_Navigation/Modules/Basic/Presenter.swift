import Foundation
import UIKit

enum PresenterError: Error {
    case wrongInput
}

protocol ModuleInput: AnyObject { }

extension ModuleInput {
    func specific<T>() throws -> T {
        guard let specified = self as? T else { throw PresenterError.wrongInput }
        return specified
    }
}

protocol Presenter: ModuleInput {
    associatedtype View
    associatedtype Router
    associatedtype Interactor
    
    var view: View! { get set }
    var interactor: Interactor! { get set }
    var router: Router! { get set }
}

