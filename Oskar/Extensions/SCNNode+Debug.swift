//
//  SCNNode+Debug.swift
//  StARs
//
//  Created by Konrad Feiler on 12.12.17.
//  Copyright © 2017 Konrad Feiler. All rights reserved.
//

import Foundation
import SceneKit

extension SCNNode {
    
    func debugNodeChildren(depth: Int = 0) {
        let inset = (0...depth).reduce("") { (res, _) -> String in res.appending("  ") }
        print(inset.appending("\(type(of: self)), \(self.name ?? "?"), scale: \(scale):"))
        if let light = light {
            print(inset.appending("  Light: \(light), cat: \(light.categoryBitMask)"))
        }
        if let material = geometry?.firstMaterial {
            print(inset.appending("  Material.lighting: \(material.lightingModel)"))
        }
        childNodes.forEach { $0.debugNodeChildren(depth: depth + 1 )}
    }
    
    func forEachChild(execute: (SCNNode) -> Void) {
        for node in childNodes {
            execute(node)
            node.forEachChild(execute: execute)
        }
    }
}
