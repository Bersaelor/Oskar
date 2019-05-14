//
//  Geometry.swift
//  Sporttotal
//
//  Copyright © 2018 sporttotal.tv gmbh. All rights reserved.
//

import CoreGraphics
import Foundation

// swiftlint:disable identifier_name
prefix operator √
prefix func √ (number: Double) -> Double {
    return sqrt(number)
}
prefix func √ (number: CGFloat) -> CGFloat {
    return sqrt(number)
}
prefix func √ (number: Int) -> CGFloat {
    return sqrt(CGFloat(number))
}

// MARK: CGRect and Size
extension CGRect {
    var center: CGPoint {
        get {
            return origin + CGVector(dx: width, dy: height) / 2.0
        }
        set {
            origin = center - CGVector(dx: width, dy: height) / 2
        }
    }
}

func + (left: CGSize, right: CGFloat) -> CGSize {
    return CGSize(width: left.width + right, height: left.height + right)
}

func - (left: CGSize, right: CGFloat) -> CGSize {
    return left + (-1.0 * right)
}

// MARK: CGPoint and CGVector math
func - (left: CGPoint, right: CGPoint) -> CGVector {
    return CGVector(dx: left.x - right.x, dy: left.y - right.y)
}

func / (left: CGVector, right: CGFloat) -> CGVector {
    return CGVector(dx: left.dx / right, dy: left.dy / right)
}

func * (left: CGVector, right: CGFloat) -> CGVector {
    return CGVector(dx: left.dx * right, dy: left.dy * right)
}

func + (left: CGPoint, right: CGVector) -> CGPoint {
    return CGPoint(x: left.x + right.dx, y: left.y + right.dy)
}

func + (left: CGVector, right: CGVector) -> CGVector {
    return CGVector(dx: left.dx + right.dx, dy: left.dy + right.dy)
}

func + (left: CGVector?, right: CGVector?) -> CGVector? {
    if let left = left, let right = right {
        return CGVector(dx: left.dx + right.dx, dy: left.dy + right.dy)
    } else {
        return nil
    }
}

func - (left: CGPoint, right: CGVector) -> CGPoint {
    return CGPoint(x: left.x - right.dx, y: left.y - right.dy)
}

public func + (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

public func += (left: inout CGPoint, right: CGPoint) {
    // swiftlint:disable:next shorthand_operator
    left = left + right
}

public func - (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

public func -= (left: inout CGPoint, right: CGPoint) {
    // swiftlint:disable:next shorthand_operator
    left = left - right
}

public func norm(_ point: CGPoint) -> CGFloat {
    return √(point.x * point.x + point.y * point.y)
}

public func * (scalar: CGFloat, right: CGPoint) -> CGPoint {
    return CGPoint(x: scalar * right.x, y: scalar * right.y)
}

public func * (scalar: CGFloat, right: CGRect) -> CGRect {
    return CGRect(x: scalar * right.minX, y: scalar * right.minY,
                  width: scalar * right.width, height: scalar * right.height)
}

public func *= (left: inout CGPoint, right: CGFloat) {
    left = right * left
}

extension CGPoint {
    /// Returns the angle in radians of the vector described by the CGVector.
    /// The range of the angle is 0 to 2π; an angle of 0 points to the right.
    public var angle: CGFloat {
         return atan2(self.y, self.x) + CGFloat(self.y < 0 ? 2 * CGFloat.pi : 0.0)
    }
    
    public static func angledVec(_ angle: CGFloat) -> CGPoint {
        return CGPoint(x: cos(angle), y: sin(angle))
    }
    
    public func rotated(_ angle: CGFloat) -> CGPoint {
        let s = sin(angle)
        let c = cos(angle)
        return CGPoint(x: c * self.x - s * self.y, y: s * self.x + c * self.y)
    }
    
    // swiftlint:disable identifier_name
    public func rotated(sin s: CGFloat, cos c: CGFloat) -> CGPoint {
        return CGPoint(x: c * self.x - s * self.y, y: s * self.x + c * self.y)
    }
    // swiftlint:enable identifier_name
    
    public var normalized: CGPoint {
        return 1 / norm(self) * self
    }
}

extension CGPoint {
    init(_ vector: CGVector) {
        self.init(x: vector.dx, y: vector.dy)
    }
}

extension CGVector {
    init(_ point: CGPoint) {
        self.init(dx: point.x, dy: point.y)
    }
    
    func apply(_ transform: CGAffineTransform) -> CGVector {
        return CGVector(CGPoint(self).applying(transform))
    }
    
    func round(toScale scale: CGFloat) -> CGVector {
        return CGVector(dx: CoreGraphics.round(dx * scale) / scale,
                        dy: CoreGraphics.round(dy * scale) / scale)
    }
    
    var quadrance: CGFloat {
        return dx * dx + dy * dy
    }
    
    var normal: CGVector? {
        if !(dx.isZero && dy.isZero) {
            return CGVector(dx: -dy, dy: dx)
        } else {
            return nil
        }
    }
    
    /// CGVector pointing in the same direction as self, with a length of 1.0 - or nil if the length is zero.
    var normalize: CGVector? {
        let quadrance = self.quadrance
        if quadrance > 0.0 {
            return self / √(quadrance)
        } else {
            return nil
        }
    }
}
