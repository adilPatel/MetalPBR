//
//  Material.swift
//  MetalPBR
//
//  Created by Adil Patel on 14/09/2018.
//  Copyright © 2018 Adil Patel. All rights reserved.
//

import Foundation
import Metal
import MetalKit
import ModelIO
import simd

/// This structure holds all the textures required for a physically-based material. If a texture is not supplied, a blank one will be created.
struct Material {
       
    var baseColour = Texture()
    var ambientOcclusion = Texture()
    var metallic   = Texture()
    var roughness  = Texture()
    var normal     = Texture()
    var emissive   = Texture()
    
    init(material sourceMaterial: MDLMaterial?, textureLoader: MTKTextureLoader) {
        
        baseColour = Texture(for: .baseColor, in: sourceMaterial, textureLoader: textureLoader)
        ambientOcclusion = Texture(for: .ambientOcclusion, in: sourceMaterial, textureLoader: textureLoader)
        metallic   = Texture(for: .metallic, in: sourceMaterial, textureLoader: textureLoader)
        roughness  = Texture(for: .roughness, in: sourceMaterial, textureLoader: textureLoader)
        normal     = Texture(for: .tangentSpaceNormal, in: sourceMaterial, textureLoader: textureLoader)
        emissive   = Texture(for: .emission, in: sourceMaterial, textureLoader: textureLoader)
        
    }
    
    init(baseColourName: String?,
         ambientOcclusionName: String?,
         metallicName: String?,
         roughnessName: String?,
         normalName: String?,
         emissiveName: String?,
         device: MTLDevice) {
        
        let storageMode = NSNumber(value: MTLStorageMode.`private`.rawValue)
        let textureUsage = NSNumber(value: MTLTextureUsage.shaderRead.rawValue)
        
        let options = [MTKTextureLoader.Option.textureStorageMode : storageMode,
                       MTKTextureLoader.Option.textureUsage : textureUsage]
        
        if let baseColourName = baseColourName {
            baseColour = Texture(fromAssetCatalogueNamed: baseColourName, options: options, device: device)
        }
        
        if let ambientOcclusionName = ambientOcclusionName {
            ambientOcclusion = Texture(fromAssetCatalogueNamed: ambientOcclusionName, options: options, device: device)
        }
        
        if let metallicName = metallicName {
            metallic = Texture(fromAssetCatalogueNamed: metallicName, options: options, device: device)
        }
        
        if let roughnessName = roughnessName {
            roughness = Texture(fromAssetCatalogueNamed: roughnessName, options: options, device: device)
        }
        
        if let normalName = normalName {
            normal = Texture(fromAssetCatalogueNamed: normalName, options: options, device: device)
        }
        
        if let emissiveName = emissiveName {
            emissive = Texture(fromAssetCatalogueNamed: emissiveName, options: options, device: device)
        }
        
        
    }
    
    func bindAlbedoToShader(encoder: MTLRenderCommandEncoder) {
        baseColour.bindToFragmentShader(withDefault: Texture.blackColour, encoder: encoder, index: TextureIndex.albedo.rawValue)
    }
    
    func bindNormalToShader(encoder: MTLRenderCommandEncoder) {
        normal.bindToFragmentShader(withDefault: Texture.blankNormalMap, encoder: encoder, index: TextureIndex.normal.rawValue)
    }
    
    func bindTexturesToShader(encoder: MTLRenderCommandEncoder) {
        
        baseColour.bindToFragmentShader(withDefault: Texture.blackColour, encoder: encoder, index: TextureIndex.albedo.rawValue)
        ambientOcclusion.bindToFragmentShader(withDefault: Texture.whiteColour, encoder: encoder, index: TextureIndex.AO.rawValue)
        metallic.bindToFragmentShader(withDefault: Texture.blackColour, encoder: encoder, index: TextureIndex.metallic.rawValue)
        roughness.bindToFragmentShader(withDefault: Texture.blackColour, encoder: encoder, index: TextureIndex.roughness.rawValue)
        normal.bindToFragmentShader(withDefault: Texture.blankNormalMap, encoder: encoder, index: TextureIndex.normal.rawValue)
        emissive.bindToFragmentShader(withDefault: Texture.blackColour, encoder: encoder, index: TextureIndex.emissive.rawValue)
        
    }
    
    
}
