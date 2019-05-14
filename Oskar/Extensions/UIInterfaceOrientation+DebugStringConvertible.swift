//
//  UIInterfaceOrientation+DebugStringConvertible.swift
//  Oskar
//
//  Created by Konrad Feiler on 14.05.19.
//  Copyright © 2019 Konrad Feiler. All rights reserved.
//

import UIKit

extension UIInterfaceOrientation: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        switch self {
        case .portrait: return "portrait"
        case .landscapeLeft: return "landscapeLeft"
        case .landscapeRight: return "landscapeRight"
        case .portraitUpsideDown: return "portraitUpsideDown"
        case .unknown: return "unknown"
        @unknown default: return "unknown"
        }
    }
    
}
