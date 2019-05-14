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
        nodes.connect(to: sceneView)
        nodes.errorHandler = self.display(error:)
        nodes.sessionInteruptedHandler = sessionInterrupted
        nodes.sessionInterruptionEndedHandler = sessionInterruptionEnded

        sceneView.antialiasingMode = SCNAntialiasingMode.multisampling4X

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
    
    private func displayErrorMessage(title: String, message: String) {
        // Blur the background.
        
        // Present an alert informing about the error that has occurred.
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let restartAction = UIAlertAction(title: "Restart Session", style: .default) { _ in
            alertController.dismiss(animated: true, completion: nil)
            self.resetTracking()
        }
        alertController.addAction(restartAction)
        present(alertController, animated: true, completion: nil)
    }
    
    private func display(error: Error) {
        let errorWithInfo = error as NSError
        let messages = [
            errorWithInfo.localizedDescription,
            errorWithInfo.localizedFailureReason,
            errorWithInfo.localizedRecoverySuggestion
        ]
        let errorMessage = messages.compactMap({ $0 }).joined(separator: "\n")
        
        DispatchQueue.main.async {
            self.displayErrorMessage(title: "The AR session failed.", message: errorMessage)
        }
    }
    
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
