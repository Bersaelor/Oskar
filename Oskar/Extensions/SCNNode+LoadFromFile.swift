//
//  SCNNode+LoadFromFile.swift
//  LooC AR
//
//  Created by Konrad Feiler on 01.01.19.
//  Copyright © 2019 Konrad Feiler. All rights reserved.
//

import SceneKit

extension SCNNode {
    
    static func loadedContentForAsset(named resourceName: String, fileExtension: String = "scn") -> SCNNode {
        let url = Bundle.main.url(forResource: resourceName, withExtension: fileExtension,
                                  subdirectory: "art.scnassets")!
        let node = SCNReferenceNode(url: url)!
        node.load()
        node.name = resourceName
        
        return node
    }
    
    static func loadAsset(for model: MaskModel) -> SCNNode {
        if let url = URL(string: model.modelFileName), url.pathComponents.count > 2 {
            let node = SCNReferenceNode(url: url)!
            node.load()
            return node
            
        } else if let url = Bundle.main.url(forResource: model.modelFileName,
                                            withExtension: model.hasExtension ? "" : "scn",
                                            subdirectory: "art.scnassets") {
            let node = SCNReferenceNode(url: url)!
            node.load()
            return node
        } else {
            log.error("Failed to find \(model.modelFileName) in Bundle")
            return SCNNode()
        }
    }

}
