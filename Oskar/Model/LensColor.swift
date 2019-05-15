//
//  LensColors.swift
//  LooC AR
//
//  Created by Konrad Feiler on 15.02.18.
//  Copyright © 2018 Konrad Feiler. All rights reserved.
//

import UIKit

enum LensColor: Int, Codable {
    case clear
    case antireflective
    case shaded
    case mirrored
    case photoChromic
    
    static let orderedValues: [LensColor] = [.clear, .antireflective, .shaded, .mirrored, .photoChromic]
    
    var title: String { return "" }

    var diffuse: UIColor {
        switch self {
        case .clear:
            return UIColor(white: 0.98, alpha: 1.0)
        case .antireflective:
            return UIColor(white: 0.98, alpha: 1.0)
        case .mirrored:
            return UIColor(red: 0.15, green: 0.12, blue: 0.19, alpha: 1.0)
        case .shaded, .photoChromic:
            return UIColor(white: 0.15, alpha: 1.0)
        }
    }
    
    var iconColor: UIColor {
        switch self {
        case .clear:
            return UIColor(white: 0.9, alpha: 0.1)
        case .antireflective:
            return UIColor(white: 0.9, alpha: 0.1)
        case .mirrored:
            return UIColor(red: 0.15, green: 0.1, blue: 0.2, alpha: 1.0)
        case .shaded:
            return UIColor(white: 0.05, alpha: 1.0)
        case .photoChromic:
            return UIColor(white: 0.05, alpha: 1.0)
        }
    }
    
    var transparency: Float {
        switch self {
        case .clear:
            return 1.0
        case .antireflective:
            return 1.0
        case .mirrored:
            return 0.98
        case .shaded, .photoChromic:
            return 0.9
        }
    }
    
    var metalness: Float {
        switch self {
        case .antireflective:
            return 0.75
        case  .clear, .shaded, .photoChromic:
            return 0.95
        case .mirrored:
            return 0.8
        }
    }
    
    var roughness: Float {
        switch self {
        case .clear, .antireflective:
            return 0.03
        case .shaded, .photoChromic:
            return 0.05
        case .mirrored:
            return 0.03
        }
    }
    
    var reflectivity: Float {
        switch self {
        case .clear:
            return 0.03
        case .antireflective:
            return 0.01
        case .shaded, .photoChromic:
            return 0.09
        case .mirrored:
            return 0.1
        }
    }
    
    var imageName: String {
        switch self {
        case .clear: return "ClearGlass"
        case .antireflective: return "AntireflectiveGlass"
        case .shaded: return "ShadedGlass"
        case .mirrored: return "MirroredGlass"
        case .photoChromic: return "ChromaticGlass"
        }
    }
}
