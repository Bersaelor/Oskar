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

    private static let wallReferenceNode = SCNNode.loadedContentForAsset(named: "wall", fileExtension: "dae")

    private lazy var wallNode: SCNNode = {
        return NodeManager.wallReferenceNode.childNode(withName: "Wall", recursively: true)!
    }()

    private var models: [MaskModel]
    private var nodeForMaskModel = [MaskModel: VirtualFaceNode]()

    var glassesNode: GlassesNode? {
        return contentUpdater.virtualFaceNode as? GlassesNode
    }
    
    var faceDetectionChanged: () -> Void = { }
    
    private var spotLight: SCNLight?
    private var ambientLight: SCNLight?
    private var spotLightNode: SCNNode?
    private var ambientLightNode: SCNNode?

    private var scene: SCNScene? {
        didSet {
            log.debug("setting scene")
        }
    }
    private var rootNode: SCNNode? { return scene?.rootNode }
    private var pointOfView: SCNNode? {
        didSet {
            guard let pointOfView = pointOfView else { return }
            let distance: Float = 0.3
            rightOfScreen.name = "RightOfScreen"
            rightOfScreen.position = SCNVector3(distance, 0, -0.1)
            leftOfScreen.name = "LeftOfScreen"
            leftOfScreen.position = SCNVector3(-distance, 0, -0.1)
            pointOfView.addChildNode(rightOfScreen)
            pointOfView.addChildNode(leftOfScreen)
        }
    }
    private let rightOfScreen = SCNNode()
    private let leftOfScreen = SCNNode()

    var errorHandler: (Error) -> Void = { _ in }
    var sessionInteruptedHandler: () -> Void = { }
    var sessionInterruptionEndedHandler: () -> Void = { }
    var headAngleChangeHandler: (CGFloat, Float) -> Void = { (_, _) in }
    var updateHeadDirection: (Bool) -> Void = { _ in }

    override init() {
        models = loadPlist("Models", defaultValues: [])

        super.init()        

        createFaceGeometry()
        contentUpdater.virtualFaceNode = nodeForMaskModel[models[0]]
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
        pointOfView = sceneView.pointOfView
        contentUpdater.createExhibitionNodes(from: pointOfView)
        setupWall()
        setupSpotLight(position: SCNVector3(0, 3, 0))
        setupAmbientLight(position: SCNVector3(0, 3, 0))
        staticLight()
    }

    func resetGlassesPositions() {
        if let oldGlasses = (contentUpdater.virtualFaceNode as? FaceMeshNode)?.glasses {
            animateParentNode(of: oldGlasses, to: rightOfScreen)
            (contentUpdater.virtualFaceNode as? FaceMeshNode)?.glasses = nil
        }
        for maskModel in models {
            guard !maskModel.isFaceMesh else { continue }
            guard let maskNode = nodeForMaskModel[maskModel] as? GlassesNode else { continue }
            maskNode.templeMode = .closed
            maskNode.isSittingOnFace = false
            rightOfScreen.addChildNode(maskNode)
        }
    }
    
    func putOnFace(glassesName: String) {
        guard let glassesModel = models.first(where: { $0.displayName.lowercased() == glassesName.lowercased() }) else {
            log.warning("Failed to find glassesModel of name \(glassesName)")
            return
        }
        guard let glassesNode = nodeForMaskModel[glassesModel] as? GlassesNode else {
            log.warning("Failed to find a GlassesNode with model for name \(glassesName)")
            return
        }
        guard let faceMeshNode = contentUpdater.virtualFaceNode as? FaceMeshNode else {
            log.warning("Failed to find a FaceMeshNode in nodeForMaskModel")
            return
        }

        let animateNewGlassesOn = {
            faceMeshNode.glasses = glassesNode
            self.animateParentNode(of: glassesNode, to: faceMeshNode)
        }
        
        // remove glasses on face and move them to the left of the screen
        if let oldGlasses = faceMeshNode.glasses {
            animateParentNode(of: oldGlasses, to: leftOfScreen)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 * SCNNode.animationDuration, execute: animateNewGlassesOn)
        } else {
            animateNewGlassesOn()
        }

    }
        
    private func setupSpotLight(position: SCNVector3) {
        spotLight = SCNLight()
        spotLight?.type = SCNLight.LightType.spot
        spotLight?.castsShadow = true
        spotLight?.shadowMode = .forward
        spotLight?.shadowRadius = 10
        spotLight?.shadowSampleCount = 12
        spotLight?.shadowMapSize = CGSize(width: 500, height: 500)
        spotLight?.shadowColor = UIColor.init(white: 0.1, alpha: 0.3).cgColor
        spotLight?.spotInnerAngle = 0
        spotLight?.spotOuterAngle = 23
        
        let spotNode = SCNNode()
        spotNode.light = spotLight
        spotNode.position = position
        
        // By default the stop light points directly down the negative
        // z-axis, we want to shine it down so rotate 90deg around the
        // x-axis to point it down
        spotNode.eulerAngles = SCNVector3(-Float.pi/2, 0, 0)
        pointOfView?.addChildNode(spotNode)
        spotLightNode = spotNode
    }
    
    private func setupAmbientLight(position: SCNVector3) {
        ambientLight = SCNLight()
        ambientLight?.type = SCNLight.LightType.ambient
        
        let lightNode = SCNNode()
        lightNode.light = ambientLight
        lightNode.position = position
        lightNode.eulerAngles = SCNVector3(-Float.pi/2, 0, 0)
        
        if rootNode == nil { log.warning("rootNode shouldn't be nil at this point!") }
        pointOfView?.addChildNode(lightNode)
        ambientLightNode = lightNode
    }
    
    private func updateLight(lightEstimate: ARLightEstimate) {
        scene?.lightingEnvironment.intensity = 2 * lightEstimate.ambientIntensity / 1000.0
        [ambientLight, spotLight].forEach { (light) in
            light?.temperature = lightEstimate.ambientColorTemperature
        }
        ambientLight?.intensity = lightEstimate.ambientIntensity / 3
        
        guard let directionalLightEstimate = lightEstimate as? ARDirectionalLightEstimate else {
            // usually ambientColorTemperature is about twice as big as primaryLightIntensity
            spotLight?.intensity = lightEstimate.ambientIntensity / 4
            return
        }

        spotLight?.intensity = directionalLightEstimate.primaryLightIntensity / 8
        spotLightNode?.position = SCNVector3(directionalLightEstimate.primaryLightDirection.x,
                                             directionalLightEstimate.primaryLightDirection.y,
                                             directionalLightEstimate.primaryLightDirection.z) * -4
    }
    
    private func staticLight() {
        scene?.lightingEnvironment.intensity = 2 * 495.23 / 1000.0
        [ambientLight, spotLight].forEach { $0?.temperature = 6019.88 }
        ambientLight?.intensity = 450
        
        spotLight?.intensity = 6 // 268
        spotLightNode?.position = SCNVector3(-0.02, 1.0, 1.0)
        spotLightNode?.eulerAngles = SCNVector3(-32 * Float.pi / 180, 0, 0)
    }
    
    private func setupWall() {
        wallNode.position = SCNVector3(x: 0, y: -0.15, z: -0.15)
        pointOfView?.addChildNode(wallNode)
        
        let material = SCNMaterial()
        material.lightingModel = .physicallyBased
        material.metalness.contents = 0.0
        material.diffuse.contents = UIColor.init(white: 0.99, alpha: 1.0)
        material.roughness.contents = 0.5
        material.normal.contents = UIImage(named: "art.scnassets/plastic-normal_smooth.jpg")
        material.normal.contentsTransform = SCNMatrix4MakeScale(0.001, 0.001, 0.001)
        wallNode.geometry?.materials = [material]
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
    
    private func animateParentNode(of glasses: GlassesNode, to newParent: SCNNode) {
        let oldParent = glasses.parent
        guard oldParent != newParent else {
            log.verbose("Glasses already on the right parent: \(oldParent?.name ?? "?")")
            return
        }
        
        log.debug("Moving \(glasses.name ?? "?"), from: \(oldParent?.name ?? "?") -> \(newParent.name ?? "?")")
        
        var convertedTransform = oldParent?.convertTransform(glasses.transform, to: newParent)
        let convertedPosition = oldParent?.convertPosition(glasses.position, to: newParent)
        convertedTransform?.position = convertedPosition ?? .zero
        
        let isMovingFromPresentationToHead = newParent == contentUpdater.virtualFaceNode
//        let isMovingFromHeadToPresentation = oldParent == contentUpdater.virtualFaceNode

        // animate glasses on/off head movement
        var midTransform = contentUpdater.forwardHelperNode.convertTransform(.identity, to: newParent)
        let midPosition = contentUpdater.forwardHelperNode.convertPosition(.zero, to: newParent)
        midTransform.position = midPosition
        
        newParent.addChildNode(glasses)
        glasses.animateTransform(from: convertedTransform,
                                     via: midTransform,
                                     to: .identity)
        glasses.shouldAnimateNextTempleChanges = true
        glasses.isSittingOnFace = isMovingFromPresentationToHead
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
        for anchor in session.currentFrame?.anchors ?? [] {
            guard let faceAnchor = anchor as? ARFaceAnchor else { continue }
            contentUpdater.isFaceInView = faceAnchor.isTracked
        }
        
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
    }
}
