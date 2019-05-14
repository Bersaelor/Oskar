//
//  NodeManager.swift
//  LooC AR
//
//  Created by Konrad Feiler on 19.02.19.
//  Copyright © 2019 Konrad Feiler. All rights reserved.
//

import Foundation
import SceneKit
import ARKit

class NodeManager: NSObject {
    
    let contentUpdater = VirtualContentUpdater()

    private var models: [MaskModel]
    private  var nodeForMaskModel = [MaskModel: VirtualFaceNode]()

    var glassesNode: GlassesNode? {
        return contentUpdater.virtualFaceNode as? GlassesNode
    }
    
    var faceDetectionChanged: () -> Void = { }
    
    private var omniLight: SCNLight?
    private var ambientLight: SCNLight?
    private var omniLightNode: SCNNode?
    private var ambientLightNode: SCNNode?

    private var scene: SCNScene? {
        didSet {
            log.debug("setting scene")
        }
    }
    private var rootNode: SCNNode? { return scene?.rootNode }
    private var pointOfView: SCNNode?

    var errorHandler: (Error) -> Void = { _ in }
    var sessionInteruptedHandler: () -> Void = { }
    var sessionInterruptionEndedHandler: () -> Void = { }
    var shouldUpdateFaceAngles: Bool = false
    var headAngleChangeHandler: (CGFloat, Float) -> Void = { (_, _) in }
    var updateHeadDirection: (Bool) -> Void = { _ in }
    var updateHeadTracking: (Bool) -> Void = { _ in }

    override init() {
        models = loadPlist("Models", defaultValues: [])

        super.init()        

        createFaceGeometry()
        contentUpdater.virtualFaceNode = nodeForMaskModel[models[1]]
        contentUpdater.getIndexOfMask = { [weak self] mask in
            guard let modelForMask = self?.nodeForMaskModel.first(where: { $0.value == mask })?.key else { return nil }
            return self?.models.firstIndex(of: modelForMask)
        }
    }
    
    func connect(to viewModel: ViewModel) {

    }
    
    func connect(to sceneView: ARSCNView) {
        scene = sceneView.scene
        sceneView.session.delegate = self
        sceneView.delegate = contentUpdater
        sceneView.automaticallyUpdatesLighting = false
        sceneView.autoenablesDefaultLighting = false
        sceneView.scene.lightingEnvironment.contents = UIImage(named: "art.scnassets/lobby.jpg")
        sceneView.scene.lightingEnvironment.intensity = 2.0
        setupSpotLight(position: SCNVector3(0, 3, 0))
        setupAmbientLight(position: SCNVector3(0, 3, 0))
        pointOfView = sceneView.pointOfView
    }

    private func set(mask: MaskModel?) {
        guard let mask = mask else { return }
        contentUpdater.virtualFaceNode = nodeForMaskModel[mask]
    }
    
    private func setupSpotLight(position: SCNVector3) {
        omniLight = SCNLight()
        omniLight?.type = SCNLight.LightType.omni
        //        spotLight?.spotInnerAngle = 45
        //        spotLight?.spotOuterAngle = 45
        
        let spotNode = SCNNode()
        spotNode.light = omniLight
        spotNode.position = position
        
        // By default the stop light points directly down the negative
        // z-axis, we want to shine it down so rotate 90deg around the
        // x-axis to point it down
        spotNode.eulerAngles = SCNVector3(-Float.pi/2, 0, 0)
        rootNode?.addChildNode(spotNode)
        omniLightNode = spotNode
    }
    
    private func setupAmbientLight(position: SCNVector3) {
        ambientLight = SCNLight()
        ambientLight?.type = SCNLight.LightType.ambient
        
        let lightNode = SCNNode()
        lightNode.light = ambientLight
        lightNode.position = position
        lightNode.eulerAngles = SCNVector3(-Float.pi/2, 0, 0)
        
        if rootNode == nil { log.warning("rootNode shouldn't be nil at this point!") }
        rootNode?.addChildNode(lightNode)
        ambientLightNode = lightNode
    }
    
    private func updateLight(lightEstimate: ARLightEstimate) {
        scene?.lightingEnvironment.intensity = 2 * lightEstimate.ambientIntensity / 1000.0
        [ambientLight, omniLight].forEach { (light) in
            light?.temperature = lightEstimate.ambientColorTemperature
        }
        ambientLight?.intensity = lightEstimate.ambientIntensity / 3
        
        guard let directionalLightEstimate = lightEstimate as? ARDirectionalLightEstimate else {
            // usually ambientColorTemperature is about twice as big as primaryLightIntensity
            omniLight?.intensity = lightEstimate.ambientIntensity / 4
            return
        }
                
        omniLight?.intensity = directionalLightEstimate.primaryLightIntensity / 8
        omniLightNode?.position = SCNVector3(directionalLightEstimate.primaryLightDirection.x,
                                             directionalLightEstimate.primaryLightDirection.y,
                                             directionalLightEstimate.primaryLightDirection.z) * -4
    }
    
    func createFaceGeometry() {
//        guard ARFaceTrackingConfiguration.isSupported else {
//            log.warning("Not loading FaceGeometry on devices that don't support FaceID")
//            return
//        }

        let glassesGeometry: ARSCNFaceGeometry?
        let maskGeometry: ARSCNFaceGeometry?
        if ARFaceTrackingConfiguration.isSupported {
            let device: MTLDevice! = MTLCreateSystemDefaultDevice()
            glassesGeometry = ARSCNFaceGeometry(device: device, fillMesh: true)!
            maskGeometry = ARSCNFaceGeometry(device: device)!
        } else {
            glassesGeometry = nil
            maskGeometry = nil
        }
        
        for model in models {
            if model.isFaceMesh, let maskGeometry = maskGeometry {
                nodeForMaskModel[model] = FaceMeshNode(geometry: maskGeometry)
            } else {
                nodeForMaskModel[model] = GlassesNode(geometry: glassesGeometry, frameModel: model)
            }
        }
    }

    /// Adjust the central Position horizontally
    ///
    /// - Parameter position: relative value between [-1,1]
    func adjustCentralNode(offset: Float) {
        guard let oldPosition = contentUpdater.mainExhibitionNode?.position else { return }        
        // at -1/1 30cm offset
        let newHorizontalOffset = -0.3 * offset
        contentUpdater.mainExhibitionNode?.position = SCNVector3(newHorizontalOffset,
                                                                      oldPosition.y,
                                                                      oldPosition.z)
    }
}

// MARK: - ARSessionDelegate
extension NodeManager: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard let lightEstimate = session.currentFrame?.lightEstimate  else { return }
        
        updateLight(lightEstimate: lightEstimate)

        for anchor in session.currentFrame?.anchors ?? [] {
            guard let faceAnchor = anchor as? ARFaceAnchor else { continue }
            updateHeadTracking(faceAnchor.isTracked)
        }
        
        glassesNode?.lightIntensity = max(0.0, min(1.0, lightEstimate.ambientIntensity / 1000.0))
        
        updateFaceDirection()
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        log.warning("cameraDidChangeTrackingState: \(camera.trackingState)")
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        guard error is ARError else { return }
        errorHandler(error)
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        log.warning("session was interrupted")
        sessionInteruptedHandler()
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        log.warning("session Interruption ended")
        sessionInterruptionEndedHandler()
    }
    
    private func updateFaceDirection() {
        guard let maskNode = contentUpdater.virtualFaceNode, let pointOfView = pointOfView else { return }
        
        let faceForward = maskNode.convertVector(maskNode.forward(), to: nil)
        let forwardInCamSpace = pointOfView.convertVector(faceForward, from: nil)
        
        updateHeadDirection(forwardInCamSpace.x < 0)
        
        if let rootNode = rootNode, shouldUpdateFaceAngles {
            updateCircleAngles(rootNode: rootNode, pointOfView: pointOfView, and: maskNode)
        }
    }
    
    private func updateCircleAngles(rootNode: SCNNode, pointOfView: SCNNode, and maskNode: VirtualFaceNode) {
        guard let maskParent = maskNode.parent else { return }
        
        /// Helper Node to calculate the angle of the face to the camera
        let maskForwardHelperNode = SCNNode()
        rootNode.addChildNode(maskForwardHelperNode)
        defer { maskForwardHelperNode.removeFromParentNode() }
        
        let distance: Float = 0.06
        let maskPosition = maskParent.convertPosition(maskNode.position, to: nil)
        let maskForward = maskNode.convertVector(SCNVector3(x: 0, y: 0, z: -1), to: nil)
        let maskUp = maskNode.convertVector(SCNVector3(x: 0, y: 1, z: 0), to: nil)
        let camPosition = pointOfView.convertPosition(SCNVector3.zero, to: nil)
        
        // calculate angle and amplitude of correction
        let camToFace = maskPosition - camPosition
        let faceForward = maskNode.convertVector(maskNode.forward(), to: nil)
        let newAngle = CGFloat(faceForward.angle(to: camToFace))
        
        maskForwardHelperNode.position = maskPosition - distance * maskForward
        maskForwardHelperNode.look(at: maskPosition + maskForward, up: maskUp, localFront: SCNVector3(x: -1, y: 0, z: 0))
        
        var rotationDirection = maskForwardHelperNode.convertVector(camToFace - maskForward, from: nil)
        rotationDirection.x = 0
        let rotationAngle = -sign(rotationDirection.z) * rotationDirection.angle(to: SCNVector3(0, 1, 0))
        
        headAngleChangeHandler(newAngle, rotationAngle)
    }
}
