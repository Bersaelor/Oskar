//
//  Matrix4+Extensions.swift
//  StARs
//
//  Created by Konrad Feiler on 17.12.17.
//  Copyright © 2017 Konrad Feiler. All rights reserved.
//

import Foundation
import SceneKit

extension float4x4 {
    init(_ matrix: SCNMatrix4) {
        self.init([
            float4(matrix.m11, matrix.m12, matrix.m13, matrix.m14),
            float4(matrix.m21, matrix.m22, matrix.m23, matrix.m24),
            float4(matrix.m31, matrix.m32, matrix.m33, matrix.m34),
            float4(matrix.m41, matrix.m42, matrix.m43, matrix.m44)
            ])
    }
}

extension float4 {
    init(_ vector: SCNVector4) {
        self.init(vector.x, vector.y, vector.z, vector.w)
    }

    init(_ vector: SCNVector3) {
        self.init(vector.x, vector.y, vector.z, 1)
    }
}

extension SCNVector4 {
    init(_ vector: float4) {
        self.init(x: vector.x, y: vector.y, z: vector.z, w: vector.w)
    }
    
    init(_ vector: SCNVector3) {
        self.init(x: vector.x, y: vector.y, z: vector.z, w: 1)
    }
}

extension SCNVector3 {
    init(_ vector: float4) {
        self.init(x: vector.x / vector.w, y: vector.y / vector.w, z: vector.z / vector.w)
    }
}

func * (left: SCNMatrix4, right: SCNVector3) -> SCNVector3 {
    let matrix = float4x4(left)
    let vector = float4(right)
    let result = matrix * vector
    
    return SCNVector3(result)
}

public func SCNMatrix4Translate(_ m: SCNMatrix4, _ vec: SCNVector3) -> SCNMatrix4 {
    return SCNMatrix4Translate(m, vec.x, vec.y, vec.z)
}

public func SCNMatrix4MakeTranslation(_ vec: SCNVector3) -> SCNMatrix4 {
    return SCNMatrix4MakeTranslation(vec.x, vec.y, vec.z)
}

public func SCNMatrix4MakeScale(_ vec: SCNVector3) -> SCNMatrix4 {
    return SCNMatrix4MakeScale(vec.x, vec.y, vec.z)
}

extension SCNMatrix4 {
    static var identity: SCNMatrix4 {
        return SCNMatrix4(m11: 1, m12: 0, m13: 0, m14: 0, m21: 0, m22: 1, m23: 0, m24: 0, m31: 0, m32: 0, m33: 1, m34: 0, m41: 0, m42: 0, m43: 0, m44: 0)
    }
    
    var eulerAngles: SCNVector3 {
        let node = SCNNode()
        node.transform = self
        return node.eulerAngles
    }
    
    var position: SCNVector3 {
        get {
            let node = SCNNode()
            node.transform = self
            return node.position
        }
        set {
            m41 = newValue.x
            m42 = newValue.y
            m43 = newValue.z
            m44 = 1
        }
    }
}

extension SCNMatrix4: CustomDebugStringConvertible {
    public var debugDescription: String {
        return """
[
\(m11), \(m12), \(m13), \(m14),
\(m21), \(m22), \(m23), \(m24),
\(m31), \(m32), \(m33), \(m34),
\(m41), \(m42), \(m43), \(m44)
]
"""
    }
}
