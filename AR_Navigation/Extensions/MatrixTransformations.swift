import Foundation
import SceneKit
import CoreLocation

extension matrix_float4x4 {
    var translationVector: SCNVector3 {
        return SCNVector3(columns.3.x, columns.3.y, columns.3.z)
    }
    
    func translated(for vector: vector_float4) -> matrix_float4x4 {
        var translation = matrix_identity_float4x4
        translation.columns.3 = vector
        return simd_mul(self, translation)
    }
    
    
    //    column 0  column 1  column 2  column 3
    //        cosθ      0       sinθ      0    
    //         0        1         0       0    
    //       −sinθ      0       cosθ      0    
    //         0        0         0       1    
    func rotatedAroundY(by radians: Float) -> matrix_float4x4 {
        var rotation = matrix_identity_float4x4
        
        rotation.columns.0.x = cos(radians)
        rotation.columns.0.z = -sin(radians)
        
        rotation.columns.2.x = sin(radians)
        rotation.columns.2.z = cos(radians)
        
        return simd_mul(rotation.inverse, self)
    }
    
    func transformedWithCoordinates(current: CLLocationCoordinate2D, destination: CLLocationCoordinate2D) -> matrix_float4x4 {
        let distance = current.distance(to: destination)
        let bearing = current.bearing(to: destination)
        
        let position = vector_float4(0, 0, -Float(distance), 1)
        let translatedMatrix = translated(for: position)
        let rotatedMatrix = translatedMatrix.rotatedAroundY(by: Float(bearing))
        
        return rotatedMatrix
    }
    
    func toSCNMatrix4() -> SCNMatrix4 {
        return SCNMatrix4(float4x4(columns: columns))
    }
}


extension SCNMatrix4 {
    func transformedWithCoordinates(current: CLLocationCoordinate2D, destination: CLLocationCoordinate2D, thresholdDistance: Double) -> SCNMatrix4 {
        var distance = current.distance(to: destination)
        
        if distance > thresholdDistance {
            distance = thresholdDistance
        }
        
        let bearing = current.bearing(to: destination)
        
        var transform = self
        let translation = SCNMatrix4MakeTranslation(0, 0, -Float(distance))
        transform = SCNMatrix4Mult(transform, translation)
        let rotate = SCNMatrix4MakeRotation(Float(bearing), 0, 1, 0)
        transform = SCNMatrix4Mult(transform, SCNMatrix4Invert(rotate))
        
        return transform
    }
}
