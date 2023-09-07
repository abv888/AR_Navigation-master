import Foundation
import SceneKit

protocol ColorApplicable {
    func applyColor(_ color: UIColor)
}

extension ColorApplicable where Self: SCNNode {
    func applyColor(_ color: UIColor) {
        geometry?.firstMaterial?.diffuse.contents = color
    }
}
