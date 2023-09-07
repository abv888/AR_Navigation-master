import Foundation
import ARKit
import SceneKit
import CoreLocation

class SphereNode: SCNNode, ColorApplicable {
    
    var sphereGeometry: SCNSphere? {
        return geometry as? SCNSphere
    }
    
    init(radius: CGFloat, color: UIColor) {
        super.init()
        let sphere = SCNSphere(radius: radius)
        sphere.firstMaterial?.diffuse.contents = color
        
        geometry = sphere
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

