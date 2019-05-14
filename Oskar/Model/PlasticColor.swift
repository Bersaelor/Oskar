//
//  PlasticColor.swift
//  LooC AR
//
//  Created by Konrad Feiler on 15.02.18.
//  Copyright © 2018 Konrad Feiler. All rights reserved.
//

import Foundation

enum PlasticColor: Int, Codable {
    case black
    case blondeTortoise
    case darkTortoise
    case classicTortoise
    case mapleTortoise
    case vintageTortoise
    case quartz
    case ivory
    
    static let orderedValues: [PlasticColor] = [.black, .blondeTortoise, .darkTortoise, .classicTortoise,
                                               .mapleTortoise, .vintageTortoise, .quartz, .ivory]
    
    private var fileName: String {
        switch self {
        case .black: return "C00_Black.jpg"
        case .blondeTortoise: return "C10_Blonde Tortoise.jpg"
        case .darkTortoise: return "C11_Dark Tortoise.jpg"
        case .classicTortoise: return "C13_Classic Tortoise.jpg"
        case .mapleTortoise: return "C14_Maple Tortoise.jpg"
        case .vintageTortoise: return "C16_Vintage Tortoise.jpg"
        case .quartz: return "C44_Quartz.jpg"
        case .ivory: return "C52_Ivory.jpg"
        }
    }
    
    var imageName: String {
        return "art.scnassets/".appending(fileName)
    }
    
    var transparency: Float {
        switch self {
        case .quartz:
            return 0.75
        default:
            return 1.0
        }
    }
    
    
    var displayName: String { return "" }
}
