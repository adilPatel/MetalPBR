//
//  MacInputs.swift
//  MetalPBR macOS
//
//  Created by Adil Patel on 14/09/2018.
//  Copyright © 2018 Adil Patel. All rights reserved.
//

import Foundation
import Cocoa

protocol MacInputDelegate {
    
    // Methods here are optional because they're device-specific
    func keyDown(key: UInt16)
    func keyUp(key: UInt16)
    func mouseMoved(position: CGPoint)
    func mouseDragged(position: CGPoint)
    func mouseClicked(position: CGPoint)
    func mouseReleased(position: CGPoint)
    
}

extension MacInputDelegate {
    
    func keyDown(key: UInt16) {}
    func keyUp(key: UInt16) {}
    func mouseMoved(position: CGPoint) {}
    func mouseDragged(position: CGPoint) {}
    func mouseClicked(position: CGPoint) {}
    func mouseReleased(position: CGPoint) {}
    
}
