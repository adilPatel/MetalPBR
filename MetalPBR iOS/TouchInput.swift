//
//  TouchInput.swift
//  MetalPBR iOS
//
//  Created by Adil Patel on 14/09/2018.
//  Copyright © 2018 Adil Patel. All rights reserved.
//

import Foundation
import UIKit

/// Receives touch, gesture, and hardware keyboard input on iOS and iPadOS
protocol TouchInputDelegate {
    
    func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?, in view: UIView)
    func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?, in view: UIView)
    func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?, in view: UIView)
    func panned(gestureRecogniser: UIPanGestureRecognizer, in view: UIView)
    
    // Hardware keyboards (e.g. Magic Keyboard). Keys are identified by their HID usage, which
    // differs from the macOS virtual keycodes in KeyCodes.swift
    func keyDown(key: UIKeyboardHIDUsage)
    func keyUp(key: UIKeyboardHIDUsage)
    
}

extension TouchInputDelegate {
    
    func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?, in view: UIView) {}
    func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?, in view: UIView) {}
    func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?, in view: UIView) {}
    func panned(gestureRecogniser: UIPanGestureRecognizer, in view: UIView) {}
    func keyDown(key: UIKeyboardHIDUsage) {}
    func keyUp(key: UIKeyboardHIDUsage) {}
}
