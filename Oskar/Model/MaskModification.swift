//
//  MaskModification.swift
//  LooC AR
//
//  Created by Konrad Feiler on 29.10.18.
//  Copyright © 2018 Konrad Feiler. All rights reserved.
//

import Foundation

struct MaskModification: Codable {
    var frameColor: PlasticColor = .black
    var lensColor: LensColor
    var metalColor: MetalColor = .chrome
    var templeMetalColor: MetalColor = .titanium
    var size: MaskSize = .defaultSize
    var templeLength: Float?
    var bridgeWidth: Float?
    var glasWidth: Float?
    var glasHeight: Float?

    init(for maskModel: MaskModel) {
        lensColor = maskModel.shadedByDefault == true ? .shaded : .clear
        
        if let sizes = maskModel.sizes {
            if sizes.count == 1 {
                size = sizes[0]
            } else if let normalSize = sizes.first(where: { abs($0.sizeFactor - MaskSize.defaultSize.sizeFactor) < Double.ulpOfOne }) {
                size = normalSize
            }
        }
        
        templeLength = maskModel.defaultTempleLength
        bridgeWidth = maskModel.defaultBridgeSize
        glasWidth = maskModel.defaultGlasWidth
        glasHeight = maskModel.defaultGlasHeight
    }
}

extension MaskModification: Equatable { }
