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
    
    /// An object which handles all scene events, like adding an object or setting the camera
    var sceneResponder: SceneResponderDelegate! { get set }
    
    func sceneInit()
    
    /// Adds an object to the scene
    /// - Parameters:
    ///   - object: The object to add
    ///   - position: The position in the scene to add the object
    func addToScene(object: GameObject, position: SIMD3<Float>)
    
    /// Sets the active camera to an orbit camera
    /// - Parameters:
    ///   - radius: The radius of the orbit
    ///   - azimuth: The azimuth angle of the camera position with respect to its origin
    ///   - elevation: The elevation angle of the camera position with respect ti its origin
    ///   - origin: The focus of the camera orbit
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
