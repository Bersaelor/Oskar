/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An `ARSCNViewDelegate` which addes and updates the virtual face content in response to the ARFaceTracking session.
*/

import SceneKit
import ARKit

class VirtualContentUpdater: NSObject {
    
    // MARK: Configuration Properties
    
    /**
     Developer setting to display a 3D coordinate system centered on the tracked face.
     See `axesNode`.
     - Tag: ShowCoordinateOrigin
     */
    let showsCoordinateOrigin = false
    
    // MARK: Properties
    
    /// The virtual content that should be displayed and updated.
    var virtualFaceNode: VirtualFaceNode? {
        didSet {
            guard oldValue?.name != virtualFaceNode?.name else { return }
            updateMaskParentNode(suppressAnimations: true)
        }
    }
    
    var getIndexOfMask: (SCNNode) -> Int? = { _ in return nil }
    
    /**
     A reference to the node that was added by ARKit in `renderer(_:didAdd:for:)`.
     - Tag: FaceNode
     */
    private var faceNode: SCNNode?
    
    private var lastFacePos: SCNVector3?
    private var lastTimeStamp: Date?

    private let forwardHelperNode = SCNNode()

    var mainExhibitionNode: SCNNode?
    
    var angleAdjustment = CGPoint.zero
    
    private var exhibitionNodes = [SCNNode]()

    var isFaceInView: Bool = false {
        didSet {
            guard oldValue != isFaceInView else { return }
            log.debug("\(oldValue) -> \(isFaceInView)")
            updateMaskParentNode()
        }
    }
        
    private var lastRandomAngle: CGFloat?
        
    private let serialQueue = DispatchQueue(label: "com.example.apple-samplecode.ARKitFaceExample.serialSceneKitQueue")
    
    /// - Tag: FaceContentSetup
    private func updateMaskParentNode(suppressAnimations: Bool = false) {
        guard let currentMask = virtualFaceNode else { log.warning("No currentContent yet"); return }
        guard let newParent = mainExhibitionNode else {
            log.warning("no facenode to put the glasses on available yet")
            return
        }
        let oldParent = currentMask.parent
        guard oldParent != newParent else {
            log.verbose("Glasses already on the right parent: \(oldParent?.name ?? "?")")
            return
        }

        log.verbose("Moving \(virtualFaceNode?.name ?? "?"), from: \(oldParent?.name ?? "?") -> \(newParent.name ?? "?")")
        
        var convertedTransform = oldParent?.convertTransform(currentMask.transform, to: newParent)
        let convertedPosition = oldParent?.convertPosition(currentMask.position, to: newParent)
        convertedTransform?.position = convertedPosition ?? .zero

        var werePreviousGlassesOnFace = false
        // Remove all the current children.
        for child in faceNode?.childNodes ?? [] {
            guard child != forwardHelperNode else { continue }
            log.verbose("Removing \(child.name ?? "?") from faceNode")
            if child.name == nil {
                child.debugNodeChildren()
            }
            child.removeFromParentNode()
            if let index = getIndexOfMask(child) {
                werePreviousGlassesOnFace = true
                (child as? GlassesNode)?.shouldAnimateNextTempleChanges = !suppressAnimations
                (child as? GlassesNode)?.isSittingOnFace = false
                log.verbose("Putting \(child.name ?? "?") back into \(exhibitionNodes[index].name ?? "?")")
                exhibitionNodes[index].addChildNode(child)
            }
        }
        
        // animate glasses on/off head movement
        let isMovingFromPresentationToHead = !werePreviousGlassesOnFace && newParent == faceNode
        let isMovingFromHeadToPresentation = werePreviousGlassesOnFace && newParent != faceNode
        var midTransform = forwardHelperNode.convertTransform(.identity, to: newParent)
        let midPosition = forwardHelperNode.convertPosition(.zero, to: newParent)
        midTransform.position = midPosition

        newParent.addChildNode(currentMask)
        if isMovingFromPresentationToHead || isMovingFromHeadToPresentation {
            currentMask.animateTransform(from: convertedTransform,
                                         via: midTransform,
                                         to: .identity)
        }
        (currentMask as? GlassesNode)?.shouldAnimateNextTempleChanges =
            (isMovingFromPresentationToHead || isMovingFromHeadToPresentation) && !suppressAnimations
        (currentMask as? GlassesNode)?.isSittingOnFace = isFaceInView
    }
}

// MARK: - ARSCNViewDelegate
extension VirtualContentUpdater: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // Hold onto the `faceNode` so that the session does not need to be restarted when switching masks.
        faceNode = node
        faceNode?.name = "FACENODE"
        forwardHelperNode.position = SCNVector3(0, 0, 0.12)
        faceNode?.addChildNode(forwardHelperNode)
        log.verbose("Did add \(node.name ?? "?")")
        updateMaskParentNode()
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor else { return }

        virtualFaceNode?.update(withFaceAnchor: faceAnchor)
        // force faceNode to always be at the same position
        
        guard let faceNode = faceNode else { return }
        
        let cameraPositionAngleAdjuster = 0.1 * Float.pi / 180 * SCNVector3(angleAdjustment.y, angleAdjustment.x, 0)
        
        virtualFaceNode?.eulerAngles = faceNode.eulerAngles + cameraPositionAngleAdjuster
        
        guard let lastFacePos = lastFacePos, let lastTimeStamp = lastTimeStamp else {
            self.lastFacePos = faceNode.position
            self.lastTimeStamp = Date()
            return
        }
        
        let delta = faceNode.position - lastFacePos
        self.lastFacePos = faceNode.position
        self.lastTimeStamp = Date()
        let deltaTime = Date().timeIntervalSince(lastTimeStamp)
        // shrink by 33% per second
        let shrinkFactor = (1 - 0.5 * deltaTime)
        
        guard let virtualFaceNode = virtualFaceNode else { return }
        virtualFaceNode.position = Float(shrinkFactor) * (virtualFaceNode.position + delta)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        log.debug("Removed \(node.name ?? "?") for anchor \(type(of: anchor))")
    }
}

// MARK: - Central Nodes to exhibit the glasses

extension VirtualContentUpdater {
    
    func createExhibitionNodes(from pointOfView: SCNNode?) {
        let node = SCNNode()
        node.name = "ViewCenter"
        node.position = SCNVector3(0, 0, oniPad ? -0.45 : -0.4)
        pointOfView?.addChildNode(node)
        mainExhibitionNode = node
    }
}
