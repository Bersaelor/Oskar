/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An `SCNNode` subclass demonstrating how to configure overlay content.
*/

import ARKit
import SceneKit

class GlassesNode: SCNNode {
    
    private static let occlusionReferenceNode = SCNNode.loadedContentForAsset(named: "headNode", fileExtension: "dae")

    let glassesReferenceNode: SCNNode
    let maskModel: MaskModel
    
    // MARK: - Materials
    private let plastic = GlassesNode.createPlastic()
    private let metal = SCNMaterial()
    private let templeMetal = SCNMaterial()
    private let glass = SCNMaterial()
    private let clearPlastic = SCNMaterial()
    private let earMaterial = SCNMaterial()
    var textureTransformScale: Float {
        didSet {
            self.updateFrameMaterials()
            self.updateLensMaterial()
        }
    }
    // MARK: - Nodes
    lazy var bridge: SCNNode? = { glassesMainNode.childNode(withName: "BRIDGE", recursively: true) }()
    private lazy var defaultBridgeScale: SCNVector3? = { return bridge?.scale }()
    private lazy var glassesMainNode: SCNNode = {
        return glassesReferenceNode.childNode(withName: "Glasses", recursively: true)!
    }()
    private lazy var front: [SCNNode] = {
        if isFrontSplit {
            return [frontRight, frontLeft].compactMap({ $0 })
        } else {
            return [glassesMainNode.childNode(withName: "FRONT", recursively: true)].compactMap({ $0 })
        }
    }()
    lazy var frontRight: SCNNode? = { glassesMainNode.childNode(withName: "FRONT_RIGHT", recursively: true) }()
    lazy var frontLeft: SCNNode? = { glassesMainNode.childNode(withName: "FRONT_LEFT", recursively: true) }()
    private lazy var defaultFrontScale: SCNVector3? = { return frontRight?.scale }()
    private lazy var templeLeft: SCNNode = {
        return glassesMainNode.childNode(withName: "TEMPLE_LEFT", recursively: true)!
    }()
    private lazy var templeRight: SCNNode = {
        return glassesMainNode.childNode(withName: "TEMPLE_RIGHT", recursively: true)!
    }()
    private lazy var defaultTempleScale: SCNVector3 = { return templeLeft.scale }()
    private lazy var metalFrontElements: [SCNNode] = {
        if isFrontSplit {
            return [glassesMainNode.childNode(withName: "BRIDGE", recursively: true)!, frameRight!, frameLeft!]
        } else {
            return [glassesMainNode.childNode(withName: "HINGES", recursively: true)!]
        }
    }()
    lazy var frameRight: SCNNode? = { glassesMainNode.childNode(withName: "FRAME_RIGHT", recursively: true) }()
    lazy var frameLeft: SCNNode? = { glassesMainNode.childNode(withName: "FRAME_LEFT", recursively: true) }()
    private lazy var defaultFrameScale: SCNVector3? = { return frameRight?.scale }()
    private lazy var lenses: [SCNNode] = {
        if isFrontSplit {
            return [lensRight!, lensLeft!]
        } else {
            return [glassesMainNode.childNode(withName: "LENSES", recursively: true)!]
        }
    }()
    lazy var lensRight: SCNNode? = { glassesMainNode.childNode(withName: "LENS_RIGHT", recursively: true) }()
    lazy var lensLeft: SCNNode? = { glassesMainNode.childNode(withName: "LENS_LEFT", recursively: true) }()
    private lazy var defaultLensScale: SCNVector3? = { return frameRight?.scale }()
    private lazy var logo: SCNNode = {
        return glassesMainNode.childNode(withName: "LOGO_DV", recursively: true)!
    }()
    private lazy var metalLeft: SCNNode = {
        return glassesMainNode.childNode(withName: "METAL_LEFT", recursively: true)!
    }()
    private lazy var metalRight: SCNNode = {
        return glassesMainNode.childNode(withName: "METAL_RIGHT", recursively: true)!
    }()
    private lazy var defaultMetalTempleScale: SCNVector3 = { return metalLeft.scale }()
    private let faceOcclusionNode: SCNNode
    private lazy var ears: [SCNNode] = { return [leftEar, rightEar] }()
    private lazy var leftEar: SCNNode = {
        let newNode = GlassesNode.occlusionReferenceNode.childNode(withName: "EAR_LEFT", recursively: true)!.clone()
        newNode.geometry = (newNode.geometry?.copy() as? SCNGeometry)!
        return newNode
    }()
    private lazy var leftEarDefaultPosition: SCNVector3 = { return leftEar.position }()
    private lazy var rightEar: SCNNode = {
        let newNode = GlassesNode.occlusionReferenceNode.childNode(withName: "EAR_RIGHT", recursively: true)!.clone()
        newNode.geometry = (newNode.geometry?.copy() as? SCNGeometry)!
        return newNode
    }()
    private lazy var rightEarDefaultPosition: SCNVector3 = { return rightEar.position }()
    private lazy var pads: [SCNNode] = {
        if isFrontSplit {
            return [padRight, padLeft].compactMap({ $0 })
        } else {
            return glassesMainNode.childNode(withName: "PADS", recursively: true).map({ [$0] }) ?? []
        }
    }()
    lazy var padRight: SCNNode? = { glassesMainNode.childNode(withName: "PAD_RIGHT", recursively: true) }()
    lazy var padLeft: SCNNode? = { glassesMainNode.childNode(withName: "PAD_LEFT", recursively: true) }()
    lazy var leftToTemple: SCNNode? = { glassesMainNode.childNode(withName: "LEFT_TO_TEMPLE", recursively: true) }()
    lazy var rightToTemple: SCNNode? = { glassesMainNode.childNode(withName: "RIGHT_TO_TEMPLE", recursively: true) }()
    private lazy var defaultTempleDistance: Float? = self.currentTempleDistance()
    
    // MARK: - Other Properties

    /// dependent on chosen 3DModel
    private let distanceOfEarFromPivotinCM: Float = 9.7
    
    var modification: MaskModification {
        didSet {
            guard oldValue != modification else { return }
            updateFrameMaterials()
            updateLensMaterial()
            updateTempleLength()
            updateBridgeWidth()
            updateGlasSize()
            updatePads()
            updateTemplePositions()
            sizeClassFactor = Float(modification.size.sizeFactor)
        }
    }
    
    var isSittingOnFace: Bool = false {
        didSet {
            updateAfterParentChanges()
        }
    }
    
    lazy var isFrontSplit: Bool = {
        let hasLeftLens = glassesMainNode.childNode(withName: "LENS_LEFT", recursively: true) != nil
        let hasRightLens = glassesMainNode.childNode(withName: "LENS_RIGHT", recursively: true) != nil
        return hasLeftLens && hasRightLens
    }()

    private var defaultSizeFactor: Float = 1.0
    private var defaultGlassesNodeEulerAngle: SCNVector3 = .zero
    private var defaultGlassesNodePosition: SCNVector3 = .zero

    var sizeClassFactor: Float = 1.0 {
        didSet {
            let size = sizeClassFactor * defaultSizeFactor
            glassesMainNode.scale = SCNVector3(size, size, size)
        }
    }
    
    var lightIntensity: CGFloat = 0.5 {
        didSet { updateLensMaterial() }
    }
    
    var templeMode = TempleMode.open {
        didSet {
            guard oldValue != templeMode else { return }
            updateTemples()
        }
    }
    
    var glassesPosition = GlassesPosition() {
        didSet { updateGlassesPosition() }
    }
    
    var earPosition = SCNVector3.zero {
        didSet {
            leftEar.position = leftEarDefaultPosition + earPosition
            rightEar.position = rightEarDefaultPosition + earPosition
            updateGlassesPosition()
        }
    }
    
    private var noseSocketPoint = SCNVector3.zero {
        didSet {
            let sideVector = glassesMainNode.convertVector(SCNVector3(0.07, 0, 0), from: glassesMainNode.parent)
            let up = glassesMainNode.convertVector(SCNVector3(0, 0.05, 0), from: glassesMainNode.parent)
            let forwardAdj = glassesMainNode.convertVector(SCNVector3(0, 0, 0), from: glassesMainNode.parent)
            
            // we assume lenses are symmetrical in x - direction
            guard let lensNode = lenses.first else { fatalError("Expected at least one lens to be in lenses") }
            
            let minLens = lensNode.convertPosition(lensNode.boundingBox.min, to: glassesMainNode.parent)
            let maxLens = lensNode.convertPosition(lensNode.boundingBox.max, to: glassesMainNode.parent)
            let minLensY = min(minLens.y, maxLens.y)
            let midLensZ = 0.5 * (minLens + maxLens).z
            let bottomLensPoint = SCNVector3(0, minLensY, midLensZ)
            let bottomLensPointInGlasNodeCoo = glassesMainNode.convertPosition(bottomLensPoint, from: glassesMainNode.parent)

            leftPoint.position = bottomLensPointInGlasNodeCoo - sideVector
            rightPoint.position = bottomLensPointInGlasNodeCoo + sideVector
            upPoint.position = bottomLensPointInGlasNodeCoo + up + forwardAdj
            downPoint.position = bottomLensPointInGlasNodeCoo - 0.2 * up + forwardAdj
            updateGlassesPosition()
        }
    }

    // MARK: - Methods

    init(geometry: ARSCNFaceGeometry?, frameModel: MaskModel) {
        /*
         Write depth but not color and render before other objects.
         This causes the geometry to occlude other SceneKit content
         while showing the camera view beneath, creating the illusion
         that real-world objects are obscuring virtual 3D objects.
         */
        geometry?.firstMaterial!.colorBufferWriteMask = []
        faceOcclusionNode = SCNNode(geometry: geometry)
        faceOcclusionNode.name = "FACEOCCLUSION"
        faceOcclusionNode.isHidden = true
        self.maskModel = frameModel
        
        glassesReferenceNode = SCNNode.loadAsset(for: frameModel)
        glassesReferenceNode.name = frameModel.displayName.appending("ReferenceNode")

        modification = MaskModification(for: frameModel)
        
        textureTransformScale = frameModel.textureTransformScale
        
        super.init()
        
        name = frameModel.displayName
        
        defaultSizeFactor = glassesMainNode.scale.x
        defaultGlassesNodeEulerAngle = glassesMainNode.eulerAngles
        defaultGlassesNodePosition = glassesMainNode.position
        
        glassesPosition = GlassesPosition(tiltAngle: glassesMainNode.eulerAngles.x + 0.1,
                                          forwardAdjustment: glassesMainNode.position.z - 0.046,
                                          upDownAdjustment: glassesMainNode.position.y - 0.018)

        addChildNode(faceOcclusionNode)
        // Add 3D content positioned as "glasses".
        addChildNode(glassesReferenceNode)
        
        [bridge, lensLeft, lensRight, frameLeft, frameRight, frameLeft, frameRight, templeLeft, templeRight].forEach { (node) in
            node?.categoryBitMask = NodeManager.spotLight2Mask
        }
        
        setupMaterials()
        _ = defaultTempleDistance
        updateFrameMaterials()
        updateLensMaterial()
        updateTempleLength()
        updateBridgeWidth()
        updateGlasSize()
        updatePads()
        updateTemplePositions()
        setupCentrationNodes()
        updateAfterParentChanges()
    }
    
    required init?(coder aDecoder: NSCoder) { fatalError("\(#function) has not been implemented") }
    
    private func updateGlassesPosition() {
        guard isSittingOnFace else {
            glassesMainNode.eulerAngles = defaultGlassesNodeEulerAngle
            glassesMainNode.position = defaultGlassesNodePosition
            return
        }
        let earBeta = 10 * earPosition.y
        glassesMainNode.eulerAngles = SCNVector3(glassesPosition.tiltAngle + earBeta, 0, 0)
        let adjustment = SCNVector3(0, glassesPosition.upDownAdjustment, glassesPosition.forwardAdjustment)
        glassesMainNode.position = adjustment + noseSocketPoint
    }
    
    private func setupMaterials() {
        // lighting models
        [plastic, metal, templeMetal, clearPlastic].forEach { $0.lightingModel = .physicallyBased }
        
        // apply materials to nodes
        if maskModel.templesUsePadMaterial == true {
            front.forEach { $0.geometry?.materials = [plastic] }

            [templeLeft, templeRight].forEach { $0?.geometry?.materials = [clearPlastic] }
        } else {
            (front + [templeLeft, templeRight]).forEach { $0?.geometry?.materials = [plastic] }
        }

        if maskModel.allowsSeparateTempleColor {
            metalFrontElements.forEach { $0.geometry?.materials = [metal] }
            [metalLeft, metalRight].forEach { $0?.geometry?.materials = [templeMetal] }
        } else {
            (metalFrontElements + [metalLeft, metalRight]).forEach { $0?.geometry?.materials = [metal] }
        }
        
        lenses.forEach { $0.geometry?.materials = [glass] }
        
        earMaterial.colorBufferWriteMask = []
        earMaterial.diffuse.contents = UIColor(red: 0.0, green: 1.0, blue: 1.0, alpha: 1.0)
        earMaterial.lightingModel = .constant
        earMaterial.fillMode = .fill
        ears.forEach { $0.geometry?.materials = [earMaterial] }
        
        pads.forEach { $0.geometry?.materials = [clearPlastic] }
        
        setupMetalMaterial()
        setupTestBallMaterials()
    }
    
    private func setupMetalMaterial() {
        metal.setMetalColor(color: modification.metalColor)
        templeMetal.setMetalColor(color: modification.templeMetalColor)
    }
    
    private func setupTestBallMaterials() {
        ["Metalsphere", "plastiksphere"].forEach { (nodeName) in
            if let metalSphere = glassesMainNode.childNode(withName: nodeName, recursively: true) {
                metalSphere.geometry?.firstMaterial = metal
                metalSphere.isHidden = true
            }
        }
    }
    
    func updateFrameMaterials() {
        plastic.metalness.contents = 0.0
        plastic.diffuse.contents = UIImage(named: modification.frameColor.imageName)
        plastic.roughness.contents = 0.5
        plastic.normal.contents = UIImage(named: "art.scnassets/plastic-normal_smooth.jpg")

        let transform: SCNMatrix4
        if isFrontSplit, let lensLeft = lensLeft {
            transform = SCNMatrix4MakeScale(lensLeft.scale.x * textureTransformScale,
                                            lensLeft.scale.y * textureTransformScale,
                                            lensLeft.scale.z * textureTransformScale)
        } else {
            let factor = sizeClassFactor * textureTransformScale
            transform = SCNMatrix4MakeScale(factor, factor, factor)
        }

        [plastic, metal, clearPlastic].forEach { (material) in
            material.roughness.contentsTransform = transform
            material.diffuse.contentsTransform = transform
            material.normal.contentsTransform = transform
        }

        (front + [templeLeft, templeRight]).forEach { $0?.opacity = CGFloat(modification.frameColor.transparency) }
        
        pads.forEach { $0.opacity = 1 }
        if !pads.isEmpty {
            clearPlastic.transparency = 0.2
            clearPlastic.diffuse.contents = UIImage(named: "art.scnassets/scratched_light.jpg")
            clearPlastic.normal.contents =  UIImage(named: "art.scnassets/scuffed-plastic-normal.png")
            clearPlastic.roughness.contents = UIImage(named: "art.scnassets/scratched-roughness.jpg")
        }
        
        if maskModel.allowsMetalCustomization {
            if !modification.metalColor.isDefaultSceneKit {
                metal.setMetalColor(color: modification.metalColor, animated: true)
                templeMetal.setMetalColor(color: modification.templeMetalColor, animated: true)
            } else if modification.metalColor == .chrome {
                metal.setChrome()
                templeMetal.setChrome()
            } else if modification.metalColor == .goldPBR {
                metal.setGold()
                templeMetal.setGold(animated: true)
            }
        }
        
        if maskModel.isDebugImported {
            [plastic, clearPlastic, metal, templeMetal].forEach {
                $0.diffuse.contents = UIImage(named: "art.scnassets/checkerboard.png")
            }
        }
    }
    
    private func updateLensMaterial() {
        let transform: SCNMatrix4
        if isFrontSplit, let lensLeft = lensLeft {
            transform = SCNMatrix4MakeScale(lensLeft.scale.x, lensLeft.scale.y, lensLeft.scale.z)
        } else {
            transform = SCNMatrix4MakeScale(sizeClassFactor, sizeClassFactor, sizeClassFactor)
        }
        
        glass.roughness.contentsTransform = transform
        glass.diffuse.contentsTransform = transform
        glass.normal.contentsTransform = transform

        glass.lightingModel = .physicallyBased
        glass.set(lensColor: modification.lensColor, lightIntensity: lightIntensity)
        
        if maskModel.isDebugImported {
            glass.diffuse.contents = UIImage(named: "art.scnassets/checkerboard.png")
        }
    }
    
    private func updateBridgeWidth() {
        guard isFrontSplit, let defaultBridgeScale = defaultBridgeScale, let bridge = bridge else { return }
        guard let bridgeToLeft = bridge.childNode(withName: "BRIDGE_TO_LEFT", recursively: true) else { return }
        guard let bridgeToRight = bridge.childNode(withName: "BRIDGE_TO_RIGHT", recursively: true) else { return }
        guard let defaultWidth = maskModel.defaultBridgeSize, let chosenWidth = modification.bridgeWidth else { return }
        let factor = chosenWidth / defaultWidth
        bridge.scale = SCNVector3(x: factor * defaultBridgeScale.x, y: defaultBridgeScale.y, z: defaultBridgeScale.z)
        let leftBridgePos = glassesMainNode.convertPosition(bridgeToLeft.position, from: bridge)
        let rightBridgePos = glassesMainNode.convertPosition(bridgeToRight.position, from: bridge)
        [frameLeft, frontLeft, lensLeft].forEach { (node) in
            guard let node = node else { return }
            node.position = glassesMainNode.convertPosition(leftBridgePos, to: node.parent)
        }
        [frameRight, frontRight, lensRight].forEach { (node) in
            guard let node = node else { return }
            node.position = glassesMainNode.convertPosition(rightBridgePos, to: node.parent)
        }
    }
    
    private func updateGlasSize() {
        guard isFrontSplit else { return }
        guard let defaultGlasWidth = maskModel.defaultGlasWidth, let chosenWidth = modification.glasWidth else {
            log.warning("Expected a defaultGlasWidth to be present")
            return
        }
        guard let defaultGlasHeight = maskModel.defaultGlasHeight, let chosenHeight = modification.glasHeight else {
            log.warning("Expected a defaultGlasHeight to be present")
            return
        }
        let widthFactor = chosenWidth / defaultGlasWidth
        let heightFactor = chosenHeight / defaultGlasHeight
        
        if let defaultFrontScale = defaultFrontScale {
            [frontLeft, frontRight].forEach { (node) in
                node?.scale = SCNVector3(x: widthFactor * defaultFrontScale.x, y: heightFactor * defaultFrontScale.y, z: defaultFrontScale.z)
            }
        }
        
        if let defaultFrameScale = defaultFrameScale {
            [frameLeft, frameRight].forEach { (node) in
                node?.scale = SCNVector3(x: widthFactor * defaultFrameScale.x, y: heightFactor * defaultFrameScale.y, z: defaultFrameScale.z)
            }
        }

        if let defaultLensScale = defaultLensScale {
            [lensLeft, lensRight].forEach { (node) in
                node?.scale = SCNVector3(x: widthFactor * defaultLensScale.x, y: heightFactor * defaultLensScale.y, z: defaultLensScale.z)
            }
        }
    }
    
    private func updateTemplePositions() {
        guard let leftToTemple = leftToTemple, let rightToTemple = rightToTemple else { return }
        let leftPos = glassesMainNode.convertPosition(leftToTemple.position, from: leftToTemple.parent)
        let rightPos = glassesMainNode.convertPosition(rightToTemple.position, from: rightToTemple.parent)
        [metalLeft, templeLeft].forEach { (node) in
            node.position = glassesMainNode.convertPosition(leftPos, to: node.parent)
        }
        [metalRight, templeRight].forEach { (node) in
            node.position = glassesMainNode.convertPosition(rightPos, to: node.parent)
        }
    }
    
    private func updatePads() {
        guard let leftToPad = glassesMainNode.childNode(withName: "LEFT_TO_PAD", recursively: true) else { return }
        guard let rightToPad = glassesMainNode.childNode(withName: "RIGHT_TO_PAD", recursively: true) else { return }
        let leftPadPos = glassesMainNode.convertPosition(leftToPad.position, from: leftToPad.parent)
        let rightPadPos = glassesMainNode.convertPosition(rightToPad.position, from: rightToPad.parent)
        padLeft?.position = glassesMainNode.convertPosition(leftPadPos, to: padLeft?.parent)
        padRight?.position = glassesMainNode.convertPosition(rightPadPos, to: padRight?.parent)
    }
    
    private func updateTempleLength() {
        guard isFrontSplit else { return }
        guard let defaultLength = maskModel.defaultTempleLength, let chosenLength = modification.templeLength else { return }
        let factor = chosenLength / defaultLength
        [templeLeft, templeRight].forEach { (node) in
            node.scale = SCNVector3(defaultTempleScale.x, defaultTempleScale.y, defaultTempleScale.z * factor)
        }
        [metalLeft, metalRight].forEach { (node) in
            node.scale = SCNVector3(defaultMetalTempleScale.x, defaultMetalTempleScale.y, defaultMetalTempleScale.z * factor)
        }
    }
    
    func openOrCloseTemples() {
        if templeMode == .open {
            shouldAnimateNextTempleChanges = true
            templeMode = .closed
        } else if templeMode == .closed {
            shouldAnimateNextTempleChanges = true
            templeMode = .open
        }
    }
    
    private func updateAfterParentChanges() {
        isAnimatingTemples = false
        
        // when glasses aren't on face the glasses should be on the origin
        if !isSittingOnFace {
            updateGlassesPosition()
            templeMode = .closed
        }
    }
    
    var shouldAnimateNextTempleChanges = false
    private var isAnimatingTemples = false
    
    func updateTemples() {
        guard !isAnimatingTemples else { return }
        if shouldAnimateNextTempleChanges {
            isAnimatingTemples = true
            shouldAnimateNextTempleChanges = false
        }
        let leftEuler, rightEuler: SCNVector3
        if glassesMainNode.eulerAngles.x < -0.25 * Float.pi {
            leftEuler = SCNVector3(0, 0, -templeMode.angle)
            rightEuler = SCNVector3(0, 0, templeMode.angle)
        } else if glassesMainNode.eulerAngles.x < 0.25 * Float.pi {
            leftEuler = SCNVector3(0, -templeMode.angle, 0)
            rightEuler = SCNVector3(0, templeMode.angle, 0)
        } else {
            leftEuler = SCNVector3(0, 0, templeMode.angle)
            rightEuler = SCNVector3(0, 0, -templeMode.angle)
        }
        
        let nodeApplication = { (node: SCNNode, eulerAngle: SCNVector3) in
            let oldValue = node.eulerAngles
            let newValue = eulerAngle + SCNVector3(node.eulerAngles.x, 0, 0)
            let middleValue = self.isSittingOnFace ? newValue : oldValue
            node.eulerAngles = newValue
            if self.isAnimatingTemples {
                node.animateAngles(from: oldValue, intermediate: middleValue, to: newValue, delegate: self)
            }
        }

        [templeLeft, metalLeft].forEach { nodeApplication($0, leftEuler) }
        [templeRight, metalRight].forEach { nodeApplication($0, rightEuler) }
    }
    
    private func currentTempleDistance() -> Float? {
        guard let leftToTemple = leftToTemple, let rightToTemple = rightToTemple else { return nil }
        let leftPos = glassesMainNode.convertPosition(leftToTemple.position, from: leftToTemple.parent)
        let rightPos = glassesMainNode.convertPosition(rightToTemple.position, from: rightToTemple.parent)
        let vector = glassesMainNode.convertVector(rightPos - leftPos, to: nil)
        return vector.norm
    }
    
    private func templeWhenOnFaceAngle(for anchor: ARFaceAnchor) -> Float {
        let splitModelSizeDelta = defaultTempleDistance.flatMap { (defaultDistance) -> Float? in
            return currentTempleDistance().flatMap({ currentDistance in
                return currentDistance - defaultDistance })
        } ?? 0
        let sizeDeltaInCM = 0.5 * splitModelSizeDelta * 100
        let headWidthInM = (anchor.geometry.leftMaskEndPoint - anchor.geometry.rightMaskEndPoint).length()
        let headWidthInCM = headWidthInM * 100
        let sideInCM = 0.5 * headWidthInCM - (Float(maskModel.distanceOfTemplesAtEarToCenterinCM) + sizeDeltaInCM) * sizeClassFactor
        return asin(sideInCM / (distanceOfEarFromPivotinCM * sizeClassFactor))
    }
    
    // MARK: Debug Content
    
    private func setupDebugNodes() {
        log.debug("Debug mode")
        setCentrationNodes(visible: true)
    }
    
    // MARK: Centration/Measurement code
    
    /// Remove before production
    private static let ballSphere: SCNGeometry = {
        let sphere = SCNSphere(radius: 2.2 * 0.01)
        sphere.firstMaterial?.diffuse.contents = UIColor(hue: 298/360, saturation: 1.0, brightness: 0.95, alpha: 1.0)
        return sphere
    }()
    
    let leftPoint = SCNNode(geometry: GlassesNode.ballSphere.copy() as? SCNGeometry)
    let rightPoint = SCNNode(geometry: GlassesNode.ballSphere.copy() as? SCNGeometry)
    let upPoint = SCNNode(geometry: GlassesNode.ballSphere.copy() as? SCNGeometry)
    let downPoint = SCNNode(geometry: GlassesNode.ballSphere.copy() as? SCNGeometry)
    
    private func setupCentrationNodes() {
        leftPoint.name = "LEFT_CENTRATION"
        rightPoint.name = "RIGHT_CENTRATION"
        upPoint.name = "UP_CENTRATION"
        downPoint.name = "DOWN_CENTRATION"
        [leftPoint, rightPoint, upPoint, downPoint].forEach { (node) in
            glassesMainNode.addChildNode(node)
            node.scale = SCNVector3(0.1 / glassesMainNode.scale.x,
                                    0.1 / glassesMainNode.scale.y,
                                    0.1 / glassesMainNode.scale.z)
            node.isHidden = true
        }
        if let leftMat = GlassesNode.ballSphere.firstMaterial?.copy() as? SCNMaterial {
            leftMat.diffuse.contents = UIColor.green
            leftPoint.geometry?.firstMaterial = leftMat
        }
        if let rightMat = GlassesNode.ballSphere.firstMaterial?.copy() as? SCNMaterial {
            rightMat.diffuse.contents = UIColor.red
            rightPoint.geometry?.firstMaterial = rightMat
        }
    }
    
    func setCentrationNodes(visible: Bool) {
        [leftPoint, rightPoint, upPoint, downPoint].forEach { $0.isHidden = !visible }
    }
}

extension GlassesNode: VirtualFaceContent {
    func update(withFaceAnchor anchor: ARFaceAnchor) {
        guard isSittingOnFace else { log.verbose("not updating glasses that aren't on the face"); return }
        let faceGeometry = faceOcclusionNode.geometry as! ARSCNFaceGeometry
        faceGeometry.update(from: anchor.geometry)
        noseSocketPoint = (anchor.geometry.leftNosePoint + anchor.geometry.rightNosePoint) / 2

        templeMode = .onFace(angle: templeWhenOnFaceAngle(for: anchor))
    }
}

extension GlassesNode {
    private static let materialAsset = loadedContentForAsset(named: "materials")
    
    private static func createPlastic() -> SCNMaterial {
        guard let node = materialAsset.childNode(withName: "Plastic", recursively: false) else {
            fatalError("Failed to load from materials scene")
        }
        return (node.geometry?.firstMaterial?.copy() as? SCNMaterial)!
    }
}

extension GlassesNode: CAAnimationDelegate {
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if let basicAnimation = anim as? CABasicAnimation, basicAnimation.keyPath == SCNNode.angleAnimKeyPath {
            isAnimatingTemples = false
        } else if let basicAnimation = anim as? CAKeyframeAnimation, basicAnimation.keyPath == SCNNode.angleAnimKeyPath {
            isAnimatingTemples = false
        }
    }

}
