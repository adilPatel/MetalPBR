//
//  Camera.swift
//  MetalPBR
//
//  Created by Adil Patel on 14/09/2018.
//  Copyright © 2018 Adil Patel. All rights reserved.
//

import Foundation
import simd

#if os(OSX)
import Cocoa
#else
import UIKit
#endif

enum CameraType {
    
}

protocol CameraController {
    var camera: Camera { get set }
}

protocol Camera {
    
    var position: SIMD3<Float> { get set }
    
    var currentViewMatrix: simd_float4x4 { get set }
    
    var projectionMatrix: simd_float4x4 { get set }
    
    var rotationMatrix: simd_float4x4 { get set }
    
    var azimuthOffset: Float { get set }
    
    var altitudeOffset: Float { get set }
    
    mutating func updateState()
    
    mutating func translateCamera(byVector vector: SIMD3<Float>)
    
    mutating func rotateX(byAngle angle: Float)
    
    mutating func rotateY(byAngle angle: Float)
    
    mutating func rotateZ(byAngle angle: Float)
    
    
}

extension Camera {
    
    
    mutating func translateCamera(byVector vector: SIMD3<Float>) {
        // After much pondering and brain-melting, it was found that the transformation
        // order needs to be reversed for the transformations to make sense.
        currentViewMatrix = currentViewMatrix * Maths.createTranslationMatrix(vector: -vector)
        position = position + vector
    }
    
    mutating func rotateX(byAngle angle: Float) {
        currentViewMatrix = currentViewMatrix * Maths.createXRotation(radians: -angle)
    }
    
    mutating func rotateY(byAngle angle: Float) {
        currentViewMatrix = currentViewMatrix * Maths.createYRotation(radians: -angle)
    }
    
    mutating func rotateZ(byAngle angle: Float) {
        currentViewMatrix = currentViewMatrix * Maths.createZRotation(radians: -angle)
    }
    
}

struct OrbitCamera: Camera {

    //    var movementInputDevice: InputDevices!

    var position = SIMD3<Float>(0.0, 0.0, 0.0)
    
    var origin = SIMD3<Float>(0.0, 0.0, 0.0)
    
    var azimuth: Float = 0.0

    var altitude: Float = .pi / 2.0

    var azimuthOffset: Float = 0.0

    var altitudeOffset: Float = 0.0

    var currentViewMatrix = matrix_identity_float4x4

    var projectionMatrix: simd_float4x4

    // This is only used for the skybox
    var rotationMatrix = matrix_identity_float4x4

    var radius: Float

    init(fovy: Float,
         aspectRatio: Float,
         nearZ: Float,
         farZ: Float,
         radius: Float,
         azimuth: Float,
         elevation: Float,
         origin: SIMD3<Float>) {


        projectionMatrix = Maths.createProjectionMatrix(fovy: fovy,
                                                        aspectRatio: aspectRatio,
                                                        nearZ: nearZ,
                                                        farZ: farZ)
        
        self.radius = radius
        self.origin = origin
        
        currentViewMatrix = Maths.createTranslationMatrix(vector: -origin)
        
        position = origin + radius * SIMD3<Float>(sinf(azimuth) * cosf(elevation), sinf(azimuth) * sinf(elevation), sinf(elevation))
        
        translateCamera(byVector: position)

    }


    mutating func updateState() {

        rotateY(byAngle: -azimuth)
        rotateX(byAngle: altitudeOffset)
        rotateY(byAngle: azimuth + azimuthOffset)

        rotationMatrix = currentViewMatrix

        azimuth += azimuthOffset
        altitude += altitudeOffset

        position = origin + radius * SIMD3<Float>(cosf(azimuth) * sinf(altitude), sinf(azimuth) * sinf(altitude), sinf(azimuth) * cosf(altitude))

        azimuthOffset = 0.0
        altitudeOffset = 0.0

    }
    

}


