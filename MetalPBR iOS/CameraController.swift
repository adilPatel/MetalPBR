//
//  CameraController.swift
//  MetalPBR iOS
//
//  Created by Adil Patel on 14/09/2018.
//  Copyright © 2018 Adil Patel. All rights reserved.
//

import UIKit
import simd

final class OrbitCameraController: NSObject, TouchInputDelegate, CameraController {    
    
    var camera: Camera
    
    let elevationSensitivity: Float = -0.01
    let azimuthSensitivity: Float = 0.01
    
    // How quickly the camera orbits while a key is held, in radians per second
    let keyboardRotationSpeed: Float = 1.5
    
    // The keys currently held down on a hardware keyboard
    private var heldKeys = Set<UIKeyboardHIDUsage>()
    
    // The time of the previous update, used to make keyboard rotation independent of frame rate
    private var lastUpdateTime: CFTimeInterval?
    
    init(camera: Camera) {
        self.camera = camera
    }
    
    func panned(gestureRecogniser: UIPanGestureRecognizer, in view: UIView) {
        let delta = gestureRecogniser.translation(in: view)
        camera.azimuthOffset = azimuthSensitivity * Float(delta.x)
        camera.altitudeOffset = elevationSensitivity * Float(delta.y)
        
        gestureRecogniser.setTranslation(.zero, in: view)
        
    }
    
    func keyDown(key: UIKeyboardHIDUsage) {
        heldKeys.insert(key)
    }
    
    func keyUp(key: UIKeyboardHIDUsage) {
        heldKeys.remove(key)
    }
    
    func update() {
        
        let now = CACurrentMediaTime()
        defer { lastUpdateTime = now }
        
        // Nothing to do until a key is held. Without a previous timestamp we skip a frame rather
        // than guess how long it's been
        guard !heldKeys.isEmpty, let lastUpdateTime else { return }
        
        // Clamp the step so a stalled frame doesn't make the camera jump
        let step = keyboardRotationSpeed * Float(min(now - lastUpdateTime, 0.1))
        
        // The arrow keys (and WASD) move the camera in the same direction as dragging the same way
        var direction = SIMD2<Float>.zero
        if heldKeys.contains(.keyboardRightArrow) || heldKeys.contains(.keyboardD) { direction.x += 1 }
        if heldKeys.contains(.keyboardLeftArrow) || heldKeys.contains(.keyboardA) { direction.x -= 1 }
        if heldKeys.contains(.keyboardUpArrow) || heldKeys.contains(.keyboardW) { direction.y += 1 }
        if heldKeys.contains(.keyboardDownArrow) || heldKeys.contains(.keyboardS) { direction.y -= 1 }
        
        // Add rather than assign, so keyboard and touch input combine within a frame
        camera.azimuthOffset += step * direction.x
        camera.altitudeOffset += step * direction.y
        
    }
    
}
