//
//  Scene.swift
//  MetalPBR
//
//  Created by Adil Patel on 08/07/2019.
//  Copyright © 2019 Adil Patel. All rights reserved.
//

import Foundation

/// This protocol is conformed to by all scenes.
protocol Scene {
    
    var sceneResponder: SceneResponderDelegate! { get set }
    
    func sceneInit()
    
    func addToScene(object: GameObject, position: SIMD3<Float>)
    
    func setOrbitCamera(withRadius radius: Float, azimuth: Float, elevation: Float, origin: SIMD3<Float>)
    
}

extension Scene {
    
    func addToScene(object: GameObject, position: SIMD3<Float>) {
        sceneResponder.addedToScene(object: object, position: position)
    }
    
    func setOrbitCamera(withRadius radius: Float, azimuth: Float, elevation: Float, origin: SIMD3<Float>) {
        sceneResponder.orbitCameraWasSet(withRadius: radius, azimuth: azimuth, elevation: elevation, origin: origin)
    }
    
}

/// Every scene needs a scene responder to handle events like object creation. Scene responders conform to this protocol.
protocol SceneResponderDelegate {
    
    func addedToScene(object: GameObject, position: SIMD3<Float>)
    
    func orbitCameraWasSet(withRadius radius: Float, azimuth: Float, elevation: Float, origin: SIMD3<Float>)
    
}
