//
//  ViewModel.swift
//  Oskar
//
//  Created by Konrad Feiler on 14.05.19.
//  Copyright © 2019 Konrad Feiler. All rights reserved.
//

import Foundation

class ViewModel {
    
    func nextStep() {
        currentStepIndex = (currentStepIndex + 1) % VideoStep.all.count
    }
    
    var currentStep: VideoStep { return VideoStep.all[currentStepIndex] }
    var stepChanged: (VideoStep) -> Void = { _ in }
    
    private var currentStepIndex: Int = 0 {
        didSet {
            guard oldValue != currentStepIndex else { return }
            stepChanged(currentStep)
        }
    }
}

enum VideoStep: String {
    case idle
    case startVideoRecording
    case skoll
    case sami
    case bor
    case colorA
    case colorB
    case colorC
    case endRecording
    
    static var all: [VideoStep] = [
        .idle,
        .startVideoRecording,
        .skoll,
        .sami,
        .bor,
        .colorA,
        .colorB,
        .colorC,
        .endRecording
    ]
    
    var metalColor: MetalColor? {
        switch self {
        case .colorA: return .black
        case .colorB: return .turquoise
        case .colorC: return .titanium
        default: return nil
        }
    }
}
