//
//  SCNMaterial+Metals.swift
//  LooC AR
//
//  Created by Konrad Feiler on 15.02.18.
//  Copyright © 2018 Konrad Feiler. All rights reserved.
//

import SceneKit

extension SCNMaterial {
    
    func setGold() {
        metalness.contents = UIColor(white: 1.0, alpha: 1.0)
        roughness.contents = UIImage(named: "art.scnassets/streakedmetal-roughness.png")
        diffuse.contents = UIColor(red: 0.75164, green: 0.60648, blue: 0.22648, alpha: 1.0)
    }
    
    func setChrome() {
        metalness.contents = UIImage(named: "art.scnassets/streakedmetal-metalness.png")
        roughness.contents = UIImage(named: "art.scnassets/scratched-roughness2.jpg")
        diffuse.contents = UIImage(named: "art.scnassets/streakedmetal-albedo.png")
    }

    func setMetalColor(color: MetalColor) {        
        metalness.contents = 1.0
        roughness.contents = 0.25
        roughness.contents = UIImage(named: "art.scnassets/noise_25%.png")
        diffuse.contents = UIColor(named: color.rawValue)

        let transformScale: Float = 4
        let transform = SCNMatrix4MakeScale(transformScale, transformScale, transformScale)
        roughness.contentsTransform = transform
        diffuse.contentsTransform = transform
        normal.contentsTransform = transform
    }
    
}
