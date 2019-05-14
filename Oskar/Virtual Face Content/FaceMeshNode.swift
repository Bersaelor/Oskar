/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An `SCNNode` subclass demonstrating a basic use of `ARSCNFaceGeometry`.
*/

import ARKit
import SceneKit

class FaceMeshNode: SCNNode, VirtualFaceContent {
    
    init(geometry: ARSCNFaceGeometry) {
        let material = geometry.firstMaterial!
        
        material.diffuse.contents = UIColor(red: 0.0, green: 1.0, blue: 1.0, alpha: 1.0)
        material.lightingModel = .constant
        material.fillMode = .lines
        
        super.init()
        self.geometry = geometry
        name = "FaceMask"

    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("\(#function) has not been implemented")
    }
    
    // MARK: VirtualFaceContent
    
    var noseRidgePoint: SCNNode?
    var leftPoint: SCNNode?
    var rightPoint: SCNNode?
    var leftFaceEnd: SCNNode?
    var rightFaceEnd: SCNNode?

    /// - Tag: SCNFaceGeometryUpdate
    func update(withFaceAnchor anchor: ARFaceAnchor) {
        let faceGeometry = geometry as! ARSCNFaceGeometry
        faceGeometry.update(from: anchor.geometry)
        
        noseRidgePoint?.position = anchor.geometry.noseSocketPoint
        leftPoint?.position = anchor.geometry.leftNosePoint
        rightPoint?.position = anchor.geometry.rightNosePoint
        leftFaceEnd?.position = anchor.geometry.leftMaskEndPoint
        rightFaceEnd?.position = anchor.geometry.rightMaskEndPoint
    }
    
    func setupTestBalls() {
        let sphere = SCNSphere(radius: 0.2 * 0.01)
        sphere.firstMaterial?.diffuse.contents = UIColor(hue: 298/360, saturation: 1.0, brightness: 0.95, alpha: 1.0)
        noseRidgePoint = SCNNode(geometry: sphere)
        leftPoint = SCNNode(geometry: sphere)
        rightPoint = SCNNode(geometry: sphere)
        leftFaceEnd = SCNNode(geometry: sphere)
        rightFaceEnd = SCNNode(geometry: sphere)

        [noseRidgePoint!, leftPoint!, rightPoint!, leftFaceEnd!, rightFaceEnd!].forEach { (node) in
            addChildNode(node)
        }
    }
}
