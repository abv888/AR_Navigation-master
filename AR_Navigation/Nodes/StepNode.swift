import Foundation
import MapKit
import SceneKit

class StepNode: GlobalNode<MKRoute.Step> {
    
    var sphereNode: SphereNode!
    
    override init(element: MKRoute.Step) {
        super.init(element: element)
        
        let node = SphereNode(radius: 0.5, color: .randomPrettyColor)
        addChildNode(node)
        sphereNode = node
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateWith(currentCameraTransform: matrix_float4x4, currentCoordinates: CLLocationCoordinate2D, thresholdDistance: Double) {
        var identity = matrix_identity_float4x4
        identity.columns.3.x = currentCameraTransform.columns.3.x
        identity.columns.3.y = simdTransform.columns.3.y
        identity.columns.3.z = currentCameraTransform.columns.3.z
        
        transform = identity.toSCNMatrix4().transformedWithCoordinates(current: currentCoordinates,
                                                                       destination: element.polyline.coordinate,
                                                                       thresholdDistance: thresholdDistance)
    }
    
    func applyColor(_ color: UIColor) {
        sphereNode?.applyColor(color)
    }
}
