import Foundation
import ARKit
import SceneKit
import CoreLocation

class TextNode: SCNNode {
    
    var textGeometry: SCNText? {
        return geometry as? SCNText
    }
    
    init(text: String, color: UIColor, size: CGFloat) {
        super.init()
        
        let textShape = SCNText(string: text, extrusionDepth: 0)
        textShape.font = UIFont(name: "HelveticaNeue", size: size)
        textShape.firstMaterial?.diffuse.contents = color
        textShape.isWrapped = true
        textShape.alignmentMode = convertFromCATextLayerAlignmentMode(CATextLayerAlignmentMode.center)
        textShape.truncationMode = convertFromCATextLayerTruncationMode(CATextLayerTruncationMode.end)
        //textShape.containerFrame =
        
        geometry = textShape
    }
    
    func setText(_ text: String) {
        textGeometry?.string = text
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}



// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromCATextLayerAlignmentMode(_ input: CATextLayerAlignmentMode) -> String {
	return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromCATextLayerTruncationMode(_ input: CATextLayerTruncationMode) -> String {
	return input.rawValue
}
