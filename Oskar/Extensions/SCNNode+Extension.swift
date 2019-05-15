//
//  SCNNode+Extension.swift
//  StARs
//
//  Created by Konrad Feiler on 19.12.17.
//  Copyright © 2017 Konrad Feiler. All rights reserved.
//

import SceneKit

extension SCNNode {
    func fadeIn() {
        SCNTransaction.animationDuration = 0.8
        opacity = 1.0
    }
    
    func fadeBackgroundCubeOpacity() {
        SCNTransaction.animationDuration = 0.8
        childNodes.first?.opacity = 0.85
    }
    
    func forward() -> SCNVector3 {
        return float4x4(transform).forward()
    }
    
    static var animationDuration: CFTimeInterval { return 0.6 }
    static var angleAnimKeyPath: String { return "eulerAngles" }
    
    func animateTransform(from oldTransform: SCNMatrix4?,
                          via middleTranform: SCNMatrix4?,
                          to newTransform: SCNMatrix4) {
        guard let oldTransform = oldTransform, let middleTranform = middleTranform else { return }
        let firstAnim = CABasicAnimation(keyPath: "transform")
        firstAnim.fromValue = oldTransform
        firstAnim.toValue = middleTranform
        firstAnim.duration = 0.5 * SCNNode.animationDuration
        let secondAnim = CABasicAnimation(keyPath: "transform")
        secondAnim.fromValue = middleTranform
        secondAnim.toValue = newTransform
        secondAnim.duration = 0.5 * SCNNode.animationDuration
        secondAnim.beginTime = firstAnim.duration

        let animation = CAAnimationGroup()
        animation.animations = [firstAnim, secondAnim]
        animation.duration = SCNNode.animationDuration

        addAnimation(animation, forKey: "animateTransform")
    }
    
    func animateAngles(from oldEuler: SCNVector3,
                       intermediate middleEuler: SCNVector3? = nil,
                       to newEuler: SCNVector3,
                       delegate: CAAnimationDelegate? = nil) {
        if let middleEuler = middleEuler {
            let animation = CAKeyframeAnimation(keyPath: SCNNode.angleAnimKeyPath)
            animation.duration = SCNNode.animationDuration
            animation.values = [oldEuler, middleEuler, newEuler]
            animation.keyTimes = [0, 0.5, 1]
            animation.delegate = delegate
            addAnimation(animation, forKey: "animateAngles")
        } else {
            let animation = CABasicAnimation(keyPath: SCNNode.angleAnimKeyPath)
            animation.duration = SCNNode.animationDuration
            animation.fromValue = oldEuler
            animation.toValue = newEuler
            animation.delegate = delegate
            addAnimation(animation, forKey: "animateAngles")
        }
    }
    
}
