//
//  MaskModel.swift
//  LooC AR
//
//  Created by Konrad Feiler on 21.10.18.
//  Copyright © 2018 Konrad Feiler. All rights reserved.
//

import Foundation

struct MaskModel: Codable, Hashable {
    let versionNumber: Int
    let imageName: String
    let categoryIdentifier: String?
    let allowsPlasticCustomization: Bool
    let allowsMetalCustomization: Bool
    let displayName: String
    let modelFileName: String
    let distanceOfTemplesAtEarToCenterinCM: Double
    let textureTransformScale: Float
    let defaultBridgeSize: Float?
    let defaultTempleLength: Float?
    let defaultGlasWidth: Float?
    let defaultGlasHeight: Float?
    let shadedByDefault: Bool?
    let brand: String
    let sizes: [MaskSize]?
    let templesUsePadMaterial: Bool?
    let extras: [String]?
}

extension MaskModel {
    
    var isFaceMesh: Bool { return imageName == "Mesh_Icon" }

    var allowsSizeAdjustment: Bool { return sizes?.count ?? 0 > 1 }
    
    var allowsSeparateTempleColor: Bool { return brand == "Grafix" }
    
    var hasExtension: Bool {
        return !(modelFileName as NSString).pathExtension.isEmpty
    }
        
    static func makeModel(with url: URL, distanceToTemples: Double) -> MaskModel {
        return MaskModel(versionNumber: 0,
                         imageName: "interfacebuilder",
                         categoryIdentifier: nil,
                         allowsPlasticCustomization: false,
                         allowsMetalCustomization: false,
                         displayName: url.pathComponents.last ?? "Imported",
                         modelFileName: url.absoluteString,
                         distanceOfTemplesAtEarToCenterinCM: distanceToTemples,
                         textureTransformScale: 1.0,
                         defaultBridgeSize: 21.0,
                         defaultTempleLength: 145,
                         defaultGlasWidth: 49,
                         defaultGlasHeight: 41,
                         shadedByDefault: true, brand: "", sizes: nil, templesUsePadMaterial: nil, extras: [])
    }
    
    var isDebugImported: Bool {
        return imageName == "interfacebuilder"
    }
    
    var bridgeSizes: [Float] {
        guard let defaultSize = defaultBridgeSize else { return [] }
        let stepSize: Float = 1
        let smallerSizes = (1 ... 5).map({ defaultSize - stepSize * Float($0) }).reversed()
        let biggerSizes = (1 ... 5).map({ defaultSize + stepSize * Float($0) })
        return smallerSizes + [defaultSize] + biggerSizes
    }

    var templeSizes: [Float] {
        guard let defaultSize = defaultTempleLength else { return [] }
        let stepSize: Float = 5
        let smallerSizes = (1 ... 5).map({ defaultSize - stepSize * Float($0) }).reversed()
        let biggerSizes = (1 ... 5).map({ defaultSize + stepSize * Float($0) })
        return smallerSizes + [defaultSize] + biggerSizes
    }
    
    var glasWidths: [Float] {
        guard let defaultSize = defaultGlasWidth else { return [] }
        let stepSize: Float = 1
        let smallerSizes = (1 ... 10).map({ defaultSize - stepSize * Float($0) }).reversed()
        let biggerSizes = (1 ... 10).map({ defaultSize + stepSize * Float($0) })
        return smallerSizes + [defaultSize] + biggerSizes
    }
    
    var glasHeights: [Float] {
        guard let defaultSize = defaultGlasHeight else { return [] }
        let stepSize: Float = 1
        let smallerSizes = (1 ... 10).map({ defaultSize - stepSize * Float($0) }).reversed()
        let biggerSizes = (1 ... 10).map({ defaultSize + stepSize * Float($0) })
        return smallerSizes + [defaultSize] + biggerSizes
    }
}
