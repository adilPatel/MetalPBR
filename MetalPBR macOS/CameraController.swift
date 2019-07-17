//
//  CameraController.swift
//  MetalPBR macOS
//
//  Created by Adil Patel on 14/09/2018.
//  Copyright © 2018 Adil Patel. All rights reserved.
//

import Cocoa
import simd

class OrbitCameraController: NSObject, MacInputDelegate, CameraController {
    
    var camera: Camera
    
    // The mouse position in screen coordinates
    var mousePosition: CGPoint? = nil
    
    // Determines how quickly the camera rotates in response to a mouse event
    let azimuthSensitivity: Float = 0.01
    
    // Determines how quickly the camera rotates in response to a mouse event
    let elevationSensitivity: Float = 0.01
    
    
    init(camera: OrbitCamera) {
        self.camera = camera
    }
    
    func mouseDragged(position: CGPoint) {
        
        if let currentPosition = mousePosition {
            let dx = Float(position.x - currentPosition.x)
            let dy = Float(position.y - currentPosition.y)
            camera.azimuthOffset  = azimuthSensitivity * dx
            camera.altitudeOffset = elevationSensitivity * dy
        }
        mousePosition = position
        
    }
    
    func mouseReleased(position: CGPoint) {
        mousePosition = nil
    }
    
}
