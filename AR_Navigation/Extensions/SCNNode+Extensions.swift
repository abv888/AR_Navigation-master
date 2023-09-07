import Foundation
import SceneKit

extension SCNNode {
    func childs<T>(matching predicate: ((T) -> Bool)? = nil) -> [T] {
        let fitting = childNodes.filter { $0 is T }.compactMap { $0 as? T }
        
        guard let predicate = predicate else { return fitting }
        return fitting.filter(predicate)
    }
}

