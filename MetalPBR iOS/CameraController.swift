//
//  CameraController.swift
//  MetalPBR iOS
//
//  Created by Adil Patel on 14/09/2018.
//  Copyright © 2018 Adil Patel. All rights reserved.
//

import UIKit
import simd

class OrbitCameraController: NSObject, TouchInputDelegate, CameraController {    
    
    var camera: Camera
    
    let elevationSensitivity: Float = -0.01
    let azimuthSensitivity: Float = 0.01
    
    init(camera: Camera) {
        self.camera = camera
    }
    
    func panned(gestureRecogniser: UIPanGestureRecognizer, in view: UIView) {
        let delta = gestureRecogniser.translation(in: view)
        camera.azimuthOffset = azimuthSensitivity * Float(delta.x)
        camera.altitudeOffset = elevationSensitivity * Float(delta.y)
        
        gestureRecogniser.setTranslation(CGPoint(x: 0.0, y: 0.0), in: view)
        
    }
    
}
