//
//  MaskSize.swift
//  LooC AR
//
//  Created by Konrad Feiler on 29.10.18.
//  Copyright © 2018 Konrad Feiler. All rights reserved.
//

import Foundation

struct MaskSize: Codable, Hashable {
    let name: String
    let sizeFactor: Double
}

extension MaskSize {
    static let defaultSize = MaskSize(name: "default", sizeFactor: 1.0)
}
