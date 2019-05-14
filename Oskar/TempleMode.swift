//
//  TempleMode.swift
//  LooC AR
//
//  Created by Konrad Feiler on 19.03.19.
//  Copyright © 2019 Konrad Feiler. All rights reserved.
//

import Foundation

enum TempleMode {
    case open
    case closed
    case onFace(angle: Float)
}

extension TempleMode: Equatable {
    
    static func == (lhs: TempleMode, rhs: TempleMode) -> Bool {
        if case .open = lhs, case .open = rhs {
            return true
        }
        else if case .closed = lhs, case .closed = rhs {
            return true
        } else if case let .onFace(lhsAngle) = lhs, case let .onFace(rhsAngle) = rhs {
            return abs(lhsAngle - rhsAngle) < 5 * Float.ulpOfOne
        } else {
            return false
        }
    }
    
    var angle: Float {
        switch self {
        case .open: return 0
        case .closed: return -4/5 * 0.5 * Float.pi
        case let .onFace(angle): return angle
        }
    }
}
