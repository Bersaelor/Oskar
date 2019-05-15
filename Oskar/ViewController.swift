//
//  ViewController.swift
//  Oskar
//
//  Created by Konrad Feiler on 14.05.19.
//  Copyright © 2019 Konrad Feiler. All rights reserved.
//

import ARKit
import SceneKit
import ReplayKit
import UIKit

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

        viewModel.stepChanged = { [weak self] step in self?.stepChanged(to: step) }
        
        nodes.createFaceGeometry()

        let panGR = UIPanGestureRecognizer(target: self, action: #selector(handlePan(recognizer:)))
        view.addGestureRecognizer(panGR)

        let tapGR = UITapGestureRecognizer(target: self, action: #selector(handleTap(recognizer:)))
        view.addGestureRecognizer(tapGR)
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
    
    private let recorder = RPScreenRecorder.shared()
    private var isRecording = false {
        didSet {
            guard oldValue != isRecording else { return }
            log.debug("\(oldValue) -> \(isRecording)")
        }
    }
    
    private func stepChanged(to step: VideoStep) {
        log.debug("newStep: \(step)")
        switch step {
        case .startVideoRecording:
            startRecording()
        case .endRecording:
            stopRecording()
        default:
            break
        }
    }
    
    // MARK: - User Interaction
    private var fingerPosition: CGPoint?
    
    @objc func handlePan(recognizer: UIPanGestureRecognizer) {
        let location = recognizer.location(in: view)
        switch recognizer.state {
        case .began:
            fingerPosition = location
        case .changed:
            guard let lastPosition = fingerPosition else { return }
            fingerPosition = location
            let delta: CGPoint = location - lastPosition
            nodes.contentUpdater.angleAdjustment += delta
        case .cancelled, .failed, .ended:
            fingerPosition = nil
        case .possible:
            break
        @unknown default:
            break
        }
    }
    
    @objc func handleTap(recognizer: UITapGestureRecognizer) {
        viewModel.nextStep()
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
    
    // MARK: - Video Recording Related
    
    private func startRecording() {
        guard recorder.isAvailable else {
            log.warning("Recording isn't available at the moment")
            isRecording = false
            return
        }
        
        recorder.isMicrophoneEnabled = true
        log.debug("isMicrophoneEnabled: \(recorder.isMicrophoneEnabled)")
        recorder.startRecording { (error) in
            log.debug("Recording handler called with \(String(describing: error))")
            if let error = error {
                log.error("Failed to start recording due to \(error)")
                self.isRecording = false
                return
            }
            
            self.isRecording = true
        }
    }
    
    private func stopRecording() {
        recorder.stopRecording { [weak self] (previewVC, error) in
            guard let self = self else { return }
            if let error = error {
                log.error("Failed to stop recording due to \(error)")
                self.isRecording = false
                return
            }
            
            self.isRecording = false
            
            guard let previewVC = previewVC else { return }
            previewVC.previewControllerDelegate = self
            previewVC.modalPresentationStyle = .fullScreen
            DispatchQueue.main.async {
                self.present(previewVC, animated: true, completion: {
                    log.debug("Presented Preview of Recording VC")
                })
            }
        }
    }
    
}

// MARK: - ARSCNViewDelegate

extension ViewController {
    
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

extension ViewController: RPPreviewViewControllerDelegate {
    func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
        dismiss(animated: true)
    }
}
