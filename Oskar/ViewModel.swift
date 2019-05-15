//
//  ViewModel.swift
//  Oskar
//
//  Created by Konrad Feiler on 14.05.19.
//  Copyright © 2019 Konrad Feiler. All rights reserved.
//

import Foundation

class ViewModel {
    
    func nextStep() { currentStepIndex += 1 }
    
    var currentStep: VideoStep { return VideoStep.all[currentStepIndex] }
    var stepChanged: (VideoStep) -> Void = { _ in }
    
    private var currentStepIndex: Int = 0 {
        didSet {
            guard oldValue != currentStepIndex else { return }
            stepChanged(currentStep)
        }
    }
}

enum VideoStep {
    case idle
    case startVideoRecording
    case neso
    case hyperion
    case kari
    case colorA
    case colorB
    case colorC
    case endRecording
    
    static var all: [VideoStep] = [
        .idle,
        .startVideoRecording,
        .neso,
        .hyperion,
        .kari,
        .colorA,
        .colorB,
        .colorC,
        .endRecording
    ]
}
