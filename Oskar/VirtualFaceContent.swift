/*
See LICENSE folder for this sample’s licensing information.

Abstract:
`VirtualFaceContent` provides an interface for the content in this sample to update in response to
 tracking changes.
*/

import ARKit
import SceneKit

protocol VirtualFaceContent {
    func update(withFaceAnchor: ARFaceAnchor)
}

typealias VirtualFaceNode = VirtualFaceContent & SCNNode
