//
//  ViewController.swift
//  Oskar
//
//  Created by Konrad Feiler on 14.05.19.
//  Copyright © 2019 Konrad Feiler. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    // MARK: Outlets

    @IBOutlet var sceneView: ARSCNView!
    
    // MARK: Properties
    
    private let viewModel = ViewModel()
    private let nodes = NodeManager()
    
    /// Convenience accessor for the session owned by ARSCNView.
    var session: ARSession {
        return sceneView.session
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        nodes.connect(to: viewModel)
        
        sceneView.antialiasingMode = SCNAntialiasingMode.multisampling4X

        nodes.connect(to: sceneView)
        nodes.createFaceGeometry()

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        /*
         AR experiences typically involve moving the device without
         touch input for some time, so prevent auto screen dimming.
         */
        UIApplication.shared.isIdleTimerDisabled = true
        
        resetTracking()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    /// - Tag: ARFaceTrackingSetup
    func resetTracking() {
        #if targetEnvironment(simulator)
        log.debug("not starting AR Session in simulator")
        return
        #endif
        
        let configuration = ARFaceTrackingConfiguration()
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    private func sessionInterrupted() {

    }
    
    private func sessionInterruptionEnded() {
        
        DispatchQueue.main.async {
            self.resetTracking()
        }
    }
}
