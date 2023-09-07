import Foundation
import UIKit

enum StoryboardError: Error {
    case wrongView
}

extension UIStoryboard {
    static func extractView<T: View>() throws -> T {
        guard let view = UIStoryboard(name: T.storyboardName, bundle: nil).instantiateInitialViewController() as? T else {
            throw StoryboardError.wrongView
        }
        
        return view
    }
}

