/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An `ARSCNViewDelegate` which addes and updates the virtual face content in response to the ARFaceTracking session.
*/

import SceneKit
import ARKit

class VirtualContentUpdater: NSObject {
    
    var latestFaceGeometry: ARFaceGeometry?
    
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
    
    private let forwardHelperNode = SCNNode()

    var mainExhibitionNode: SCNNode?
    
    private var exhibitionNodes = [SCNNode]()

    var isFaceInView: Bool = false {
        didSet {
            guard oldValue != isFaceInView else { return }
            updateMaskParentNode()
        }
    }
    
    private var lastRandomAngle: CGFloat?
        
    private let serialQueue = DispatchQueue(label: "com.example.apple-samplecode.ARKitFaceExample.serialSceneKitQueue")
    
    /// - Tag: FaceContentSetup
    private func updateMaskParentNode(suppressAnimations: Bool = false) {
        guard let currentMask = virtualFaceNode else { log.warning("No currentContent yet"); return }
        guard let index = getIndexOfMask(currentMask),
            let newParent = isFaceInView ? faceNode : exhibitionNodes[index] else {
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
        for child in exhibitionNodes[index].childNodes {
            log.verbose("Removing \(child.name ?? "?") from \(exhibitionNodes[index].name ?? "?")")
            child.removeFromParentNode()
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

        latestFaceGeometry = faceAnchor.geometry // 1220 vertices always
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        log.debug("Removed \(node.name ?? "?") for anchor \(type(of: anchor))")
    }
}

// MARK: - Central Nodes to exhibit the glasses

extension VirtualContentUpdater {
    
    private func animateCentralNodeRotation() {
        let angle: CGFloat
        if let lastAngle = lastRandomAngle {
            angle = lastAngle + CGFloat.pi + CGFloat.random(in: 0 ... 0.8)
        } else {
            angle = CGFloat.random(in: (0 ..< 2 * CGFloat.pi))
        }
        lastRandomAngle = angle
        
        let circleVec = CGPoint(x: 0.35, y: 0).rotated(angle)
        let rotateAction = SCNAction.rotateTo(x: circleVec.x,
                                              y: circleVec.y,
                                              z: 0,
                                              duration: 4, usesShortestUnitArc: true)
        rotateAction.timingFunction = { time in
            return simd_smoothstep(0, 1, time)
        }
        exhibitionNodes.first?.runAction(rotateAction) { [weak self] in
            self?.animateCentralNodeRotation()
        }
        exhibitionNodes.dropFirst().forEach { (node) in
            node.runAction(rotateAction)
        }
    }
}
