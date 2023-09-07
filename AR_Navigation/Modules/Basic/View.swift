import UIKit

protocol View: AnyObject {
    associatedtype Presenter
    var output: Presenter! { get set }
    
    static var storyboardName: String { get }
}
