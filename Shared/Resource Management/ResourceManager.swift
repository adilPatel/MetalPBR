//
//  ResourceManager.swift
//  MetalPBR
//
//  Created by Adil Patel on 08/07/2019.
//  Copyright © 2019 Adil Patel. All rights reserved.
//

import Foundation
import Metal

/// A high-level structure that handles the loading of resources such as meshes and textures.
struct ResourceManager {
    
    static var device: MTLDevice!
    
    static func loadModel(fromFile name: String) -> Model {
        
        return Model(fromFile: name, device: ResourceManager.device)
        
    }
    
    static func createMaterial(baseColourName: String?,
                               ambientOcclusionName: String?,
                               metallicName: String?,
                               roughnessName: String?,
                               normalName: String?,
                               emissiveName: String?) -> Material {
        
        return Material(baseColourName: baseColourName,
                        ambientOcclusionName: ambientOcclusionName,
                        metallicName: metallicName,
                        roughnessName: roughnessName,
                        normalName: normalName,
                        emissiveName: emissiveName,
                        device: ResourceManager.device)
        
    }
    
    static func loadTexture(name: String, file: String) -> Texture {
        return Texture(name: name, file: file, options: [:], device: device)
    }
    

}
