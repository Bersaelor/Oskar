//
//  ARFaceGeometry+GlassPosition.swift
//  LooC AR
//
//  Created by Konrad Feiler on 01.03.18.
//  Copyright © 2018 Konrad Feiler. All rights reserved.
//

import Foundation
import ARKit

extension ARFaceGeometry {
    
    private func point(at index: Int) -> SCNVector3 {
        let nosePoint = vertices[index]
        return SCNVector3(nosePoint.x, nosePoint.y, nosePoint.z)
    }
    
    var noseSocketPoint: SCNVector3 {
        return point(at: 36)
    }

    var leftNosePoint: SCNVector3 {
        return point(at: 801)
    }

    var rightNosePoint: SCNVector3 {
        return point(at: 370)
    }
    
    var leftMaskEndPoint: SCNVector3 {
        return point(at: 888)
    }

    var rightMaskEndPoint: SCNVector3 {
        return point(at: 467)
    }
}
