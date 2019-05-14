//
//  ExtensionsFor3D.swift
//  ARSky
//
//  Created by Konrad Feiler on 01.12.17.
//  Copyright © 2017 Konrad Feiler. All rights reserved.
//

import Foundation
import SceneKit

extension matrix_float4x4 {
    func position() -> SCNVector3 {
        return SCNVector3(columns.3.x, columns.3.y, columns.3.z)
    }
    
    func forward() -> SCNVector3 {
        let zVec = float4(0, 0, -1, 0)
        let forward = self * zVec
        return SCNVector3(forward.x, forward.y, forward.z)
    }
}

extension Double {
    var degreeInRad: Float {
        let degreesModulo = self.remainder(dividingBy: 1080)
        return Float(Double.pi * degreesModulo / 180)
    }
}

extension SCNVector3 {
    static var zero: SCNVector3 {
        return SCNVector3(x: 0, y: 0, z: 0)
    }
    
    init(value: Float) {
        self.init(value, value, value)
    }
    
    public var norm: Float {
        return sqrtf(x * x + y * y + z * z)
    }

    /**
     * Negates the vector described by SCNVector3 and returns
     * the result as a new SCNVector3.
     */
    func negate() -> SCNVector3 {
        return self * -1
    }
    
    /**
     * Negates the vector described by SCNVector3
     */
    mutating func negated() -> SCNVector3 {
        self = negate()
        return self
    }
    
    /**
     * Returns the length (magnitude) of the vector described by the SCNVector3
     */
    func length() -> Float {
        return sqrtf(x*x + y*y + z*z)
    }
    
    /**
     * Normalizes the vector described by the SCNVector3 to length 1.0 and returns
     * the result as a new SCNVector3.
     */
    func normalized() -> SCNVector3 {
        return self / length()
    }
    
    
    /// Component-wise squared vector
    ///
    /// - Returns: The vector with squared components
    func squared() -> SCNVector3 {
        return SCNVector3(x: x * x, y: y * y, z: z * z)
    }
    
    /**
     * Normalizes the vector described by the SCNVector3 to length 1.0.
     */
    mutating func normalize() -> SCNVector3 {
        self = normalized()
        return self
    }
    
    /**
     * Calculates the distance between two SCNVector3. Pythagoras!
     */
    func distance(vector: SCNVector3) -> Float {
        return (self - vector).length()
    }
    
    /**
     * Calculates the dot product between two SCNVector3.
     */
    func dot(_ vector: SCNVector3) -> Float {
        return x * vector.x + y * vector.y + z * vector.z
    }
    
    /**
     * Calculates the cross product between two SCNVector3.
     */
    func cross(vector: SCNVector3) -> SCNVector3 {
        return SCNVector3Make(y * vector.z - z * vector.y, z * vector.x - x * vector.z, x * vector.y - y * vector.x)
    }
    
    // Return the angle between this vector and the specified vector v
    func angle(to otherVector: SCNVector3) -> Float {
        // angle between 3d vectors P and Q is equal to the arc cos of their dot products over the product of
        // their magnitudes (lengths).
        //    theta = arccos( (P • Q) / (|P||Q|) )
        let dp = dot(otherVector) // dot product
        let magProduct = length() * otherVector.length() // product of lengths (magnitudes)
        return acos(dp / magProduct) // DONE
    }
}

// MARK: CGPoint and CGVector math
func - (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3(x: left.x - right.x, y: left.y - right.y, z: left.z - right.z)
}

func / (left: SCNVector3, right: Float) -> SCNVector3 {
    return SCNVector3(x: left.x / right, y: left.y / right, z: left.z / right)
}

func * (left: SCNVector3, right: Float) -> SCNVector3 {
    return SCNVector3(x: left.x * right, y: left.y * right, z: left.z * right)
}

func * (left: Float, right: SCNVector3) -> SCNVector3 {
    return right * left
}

func + (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3(x: left.x + right.x, y: left.y + right.y, z: left.z + right.z)
}

func += (left: inout SCNVector3, right: SCNVector3) {
    // swiftlint:disable:next shorthand_operator
    left = left + right
}

/**
 * Calculates the dot product between two SCNVector3 vectors
 */
func SCNVector3DotProduct(left: SCNVector3, right: SCNVector3) -> Float {
    return left.x * right.x + left.y * right.y + left.z * right.z
}

/**
 * Calculates the cross product between two SCNVector3 vectors
 */
func SCNVector3CrossProduct(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.y * right.z - left.z * right.y, left.z * right.x - left.x * right.z, left.x * right.y - left.y * right.x)
}

/**
 * Calculates the SCNVector from lerping between two SCNVector3 vectors
 */
func SCNVector3Lerp(vectorStart: SCNVector3, vectorEnd: SCNVector3, t: Float) -> SCNVector3 {
    return SCNVector3Make(vectorStart.x + ((vectorEnd.x - vectorStart.x) * t), vectorStart.y + ((vectorEnd.y - vectorStart.y) * t), vectorStart.z + ((vectorEnd.z - vectorStart.z) * t))
}

/**
 * Project the vector, vectorToProject, onto the vector, projectionVector.
 */
func SCNVector3Project(vectorToProject: SCNVector3, projectionVector: SCNVector3) -> SCNVector3 {
    let scale: Float = SCNVector3DotProduct(left: projectionVector, right: vectorToProject) / SCNVector3DotProduct(left: projectionVector, right: projectionVector)
    let v: SCNVector3 = projectionVector * scale
    return v
}
