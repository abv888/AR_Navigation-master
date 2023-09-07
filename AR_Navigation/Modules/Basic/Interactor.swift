import Foundation

protocol Interactor: AnyObject {
    associatedtype Presenter
    
    var output: Presenter! { get set }
}
