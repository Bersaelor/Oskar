//
//  MetalColor.swift
//  LooC AR
//
//  Created by Konrad Feiler on 13.11.18.
//  Copyright © 2018 Konrad Feiler. All rights reserved.
//

import UIKit

enum MetalColor: String, Codable {
    case titanium
    case black
    case limone
    case turquoise
    case pink
    case mocca
    case olive
    case ice
    case purple
    case coppa
    case graphite
    case gold
    case chrome
    case goldPBR
}

extension MetalColor {
    static var allGrafix: [MetalColor] {
        return [.titanium, .black, .limone, .turquoise, .pink, .mocca, .olive, .ice, .purple, .coppa, .graphite, .gold]
    }
    
    var isDefaultSceneKit: Bool {
        switch self {
        case .chrome, .goldPBR: return true
        default: return false
        }
    }
    
    var displayName: String { return rawValue }
    
    var uiColor: UIColor {
        return UIColor(named: self.rawValue)!
    }
}

struct MetalColorMask: OptionSet {
    let rawValue: Int
    
    static let front    = MetalColorMask(rawValue: 1 << 0)
    static let temples  = MetalColorMask(rawValue: 1 << 1)
    
    static let all: MetalColorMask = [.front, .temples]
}
