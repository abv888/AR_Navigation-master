import Foundation
import ARKit
import SceneKit

public protocol ARSceneViewManagerDelegate: AnyObject {
    func manager(_ manager: ARSceneViewManager, didUpdateState newState: ARSceneViewState)
}

public protocol ARSceneViewManagerInput {
    
    var state: ARSceneViewState { get }
    
    func launchSession()
    func pauseSession()
    func reloadSession()
    
    func currentCameraTransform() -> matrix_float4x4?
    func estimatedHeight() -> Float
    
    func addNode(_ node: SCNNode)
    func addNodes(_ nodes: [SCNNode])
    func removeAllNodes() -> [SCNNode]
}

open class ARSceneViewManager: NSObject {
    
    var updateQueue: DispatchQueue = DispatchQueue(label: "scene-update-queue")
    
    public weak var scene: ARSCNView!
    public weak var delegate: ARSceneViewManagerDelegate?
    
    public var state: ARSceneViewState = .limitedInitializing {
        didSet { delegate?.manager(self, didUpdateState: state) }
    }
    
    var session: ARSession { return scene.session }
    
    var displayFloor = true
    var recognizedHeights: [ARAnchor: Float] = [:]
    var floorNodes: [ARAnchor: FloorNode] = [:]
    
    public init(with scene: ARSCNView) {
        self.scene = scene
        
        super.init()
        if ARWorldTrackingConfiguration.isSupported {
            setup()
        }
    }
    
    //MARK: - Setup
    func setup() {
        UIApplication.shared.isIdleTimerDisabled = true
        
        setupScene()
        
        if let camera = scene.pointOfView?.camera {
            camera.wantsHDR = true
            camera.wantsExposureAdaptation = true
        }
    }
    
    func setupScene() {
        scene.delegate = self
        session.delegate = self
        
        scene.scene = SCNScene()
        
        scene.automaticallyUpdatesLighting = true
        scene.autoenablesDefaultLighting = true
        
        scene.debugOptions = [SCNDebugOptions.showWorldOrigin,
                              SCNDebugOptions.showFeaturePoints]
    }
    
    func clearStoredDate() {
        recognizedHeights.removeAll()
        floorNodes.removeAll()
    }
}

//MARK: - Logic
extension ARSceneViewManager: ARSceneViewManagerInput {
    
    public func currentCameraTransform() -> matrix_float4x4? {
        return session.currentFrame?.camera.transform
    }
    
    public func estimatedHeight() -> Float {
        return recognizedHeights.values.min() ?? -1.5
    }
    
    public func launchSession() {
        guard ARWorldTrackingConfiguration.isSupported else { return }
        
        clearStoredDate()
        let configuration = state.configuration
        session.run(configuration)
    }
    
    public func pauseSession() {
        guard ARWorldTrackingConfiguration.isSupported else { return }
        session.pause()
    }
    
    public func reloadSession() {
        guard ARWorldTrackingConfiguration.isSupported else { return }
        let options: ARSession.RunOptions =  [.resetTracking, .removeExistingAnchors]
        let configuration = state.configuration
        session.run(configuration, options: options)
    }
    
    public func addNode(_ node: SCNNode) {
        scene?.scene.rootNode.addChildNode(node)
    }
    
    public func addNodes(_ nodes: [SCNNode]) {
        nodes.forEach { addNode($0) }
    }
    
    public func removeAllNodes() -> [SCNNode] {
        let nodesToRemove = scene?.scene.rootNode.childNodes ?? []
        nodesToRemove.forEach { $0.removeFromParentNode() }
        return nodesToRemove
    }
}

//MARK: - ARSCNViewDelegate
extension ARSceneViewManager: ARSCNViewDelegate {
    public func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
    }
    
    public func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let anchor = anchor as? ARPlaneAnchor else { return }
        recognizedHeights[anchor] = node.position.y
        
        let floorNode = FloorNode(anchor: anchor)
        floorNode.applyColor(UIColor.white.withAlphaComponent(0.2))
        node.addChildNode(floorNode)
        floorNodes[anchor] = floorNode
    }
    
    public func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let anchor = anchor as? ARPlaneAnchor else { return }
        recognizedHeights[anchor] = node.position.y
        
        guard let floorNode = floorNodes[anchor] else { return }
        floorNode.updatePostition(anchor)
    }
    
    public func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        guard let anchor = anchor as? ARPlaneAnchor else { return }
        recognizedHeights[anchor] = nil
        floorNodes[anchor] = nil
    }
}

//MARK: - ARSessionDelegate
extension ARSceneViewManager: ARSessionDelegate {
    func updateState(for frame: ARFrame, trackingState: ARCamera.TrackingState) {
        switch trackingState {
        case .normal where frame.anchors.isEmpty:
            state = .normalEmptyAnchors
        case .normal:
            state = .normal
        case .notAvailable:
            state = .notAvailable
        case .limited(.excessiveMotion):
            state = .limitedExcessiveMotion
        case .limited(.insufficientFeatures):
            state = .limitedInsufficientFeatures
        case .limited(.initializing):
            state = .limitedInitializing
        case .limited(.relocalizing):
            state = .relocalizing
        @unknown default:
            state = .normal
        }
    }
    
    public func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        guard let frame = session.currentFrame else { return }
        updateState(for: frame, trackingState: frame.camera.trackingState)
    }
    
    public func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        guard let frame = session.currentFrame else { return }
        updateState(for: frame, trackingState: frame.camera.trackingState)
    }
    
    public func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        guard let frame = session.currentFrame else { return }
        updateState(for: frame, trackingState: camera.trackingState)
    }
    
    // MARK: - ARSessionObserver
    public func sessionWasInterrupted(_ session: ARSession) {
        state = .interrupted
    }
    
    public func sessionInterruptionEnded(_ session: ARSession) {
        state = .interruptionEnded
        
        reloadSession()
    }
    
    public func session(_ session: ARSession, didFailWithError error: Error) {
        state = .failed(error)
        
        reloadSession()
    }
}

public enum ARSceneViewState {
    case normal
    case normalEmptyAnchors
    case notAvailable
    case limitedExcessiveMotion
    case limitedInsufficientFeatures
    case limitedInitializing
    case relocalizing
    
    case interrupted
    case interruptionEnded
    case failed(Error)
    
    var configuration: ARWorldTrackingConfiguration {
        let configuration = ARWorldTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        configuration.worldAlignment = .gravityAndHeading
        configuration.planeDetection = .horizontal
        
        return configuration
    }
    
    public var hint: String {
        switch self {
        case .normal:
            return "AR Session prepared."
        case .normalEmptyAnchors:
            return "Move the device around to detect horizontal surfaces."
        case .notAvailable:
            return "Tracking unavailable."
        case .limitedExcessiveMotion:
            return "Tracking limited - Move the device more slowly."
        case .limitedInsufficientFeatures:
            return "Tracking limited - Point the device at an area with visible surface detail, or improve lighting conditions."
        case .limitedInitializing:
            return "Initializing AR session."
        case .relocalizing:
            return "Relocalizing AR session."
        case .interrupted:
            return "Session was interrupted"
        case .interruptionEnded:
            return "Session interruption ended"
        case .failed(let error):
            return "Session failed: \(error.localizedDescription)"
        }
    }
}
