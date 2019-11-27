//
//  Texture.swift
//  MetalPBR
//
//  Created by Adil Patel on 14/09/2018.
//  Copyright © 2018 Adil Patel. All rights reserved.
//

import Foundation
import Metal
import MetalKit

enum TextureErrors: Error {
    case badPath
}

enum DefaultTexture {
    case defaultColour
    case defaultNormal
    case noDefault
}

/// This handles the loading of textures and generates blank textures.
struct Texture {
    
    var texture: MTLTexture?
    
    static var blackColour: MTLTexture?
    static var whiteColour: MTLTexture?
    static var blankNormalMap: MTLTexture?
    
    init() {
        
    }
    
    init(name: String,
         file: String,
         createMipMaps: Bool,
         textureStorage: MTLStorageMode,
         usage: MTLTextureUsage,
         cpuCacheMode: MTLCPUCacheMode,
         device: MTLDevice) {
        
        // Take care of all the texture creation options here...
        let mipMapCreation = NSNumber(value: createMipMaps)
        let storageMode  = NSNumber(value: textureStorage.rawValue)
        let textureUsage = NSNumber(value: usage.rawValue)
        let textureCPUCacheMode = NSNumber(value: cpuCacheMode.rawValue)
        let allocateMipMaps = NSNumber(value: createMipMaps)
        
        let options = [MTKTextureLoader.Option.generateMipmaps     : mipMapCreation,
                       MTKTextureLoader.Option.textureStorageMode  : storageMode,
                       MTKTextureLoader.Option.textureUsage        : textureUsage,
                       MTKTextureLoader.Option.textureCPUCacheMode : textureCPUCacheMode,
                       MTKTextureLoader.Option.allocateMipmaps     : allocateMipMaps]
        
        // Now we create the actual texture
        let textureLoader = Texture.createTextureLoader(device: device)
        
        // Start by loading the file
        let separated = file.components(separatedBy: ".")
        guard let url = Bundle.main.url(forResource: separated[0], withExtension: separated[1]) else {
            print("ERROR: Failed to load \(file)!")
            return
        }
        do {
            try texture = textureLoader.newTexture(URL: url, options: options)
            texture?.label = name
        } catch {
            print("ERROR: Failed to create \(name) texture with error: \(error)")
        }
        
    }
    
    init(name: String, file: String, options: [MTKTextureLoader.Option : NSNumber], device: MTLDevice) {
        
        let textureLoader = Texture.createTextureLoader(device: device)
        
        // Load the file
        let separated = file.components(separatedBy: ".")
        guard let url = Bundle.main.url(forResource: separated[0], withExtension: separated[1]) else {
            print("ERROR: Failed to load \(file)!")
            return
        }
        do {
            try texture = textureLoader.newTexture(URL: url, options: options)
            texture?.label = name
        } catch {
            print("ERROR: Failed to create \(name) texture with error: \(error)")
        }
        
    }
    
    init(fromAssetCatalogueNamed name: String, usage: MTLTextureUsage, storageMode: MTLStorageMode, device: MTLDevice) {
        
        // These are simpler because mip-mapping is handled in the asset catalogue
        let storageMode = NSNumber(value: storageMode.rawValue)
        let textureUsage = NSNumber(value: usage.rawValue)
        
        let options = [MTKTextureLoader.Option.textureStorageMode : storageMode,
                       MTKTextureLoader.Option.textureUsage : textureUsage]
        
        let textureLoader = MTKTextureLoader(device: device)
        
        
        do {
            try texture = textureLoader.newTexture(name: name,
                                                   scaleFactor: 1.0,
                                                   bundle: nil,
                                                   options: options)
        } catch {
            print("ERROR: Failed to create skybox with error: \(error)")
        }
        
    }
    
    init(fromAssetCatalogueNamed name: String, options: [MTKTextureLoader.Option : NSNumber], device: MTLDevice) {
        
        // This is even simpler than the above
        let textureLoader = MTKTextureLoader(device: device)
        
        
        do {
            try texture = textureLoader.newTexture(name: name,
                                                   scaleFactor: 1.0,
                                                   bundle: nil,
                                                   options: options)
        } catch {
            print("ERROR: Failed to create skybox with error: \(error)")
        }
        
    }
    
    init(for semantic: MDLMaterialSemantic, in material: MDLMaterial?, textureLoader: MTKTextureLoader) {
        
        // It grabs a material property (like roughness) from the source texture
        guard let materialProperty = material?.property(with: semantic) else { return }
        guard let sourceTexture = materialProperty.textureSamplerValue?.texture else { return }
        
        // We aren't mip-mapping the tangent space normals
        let wantMips = materialProperty.semantic != .tangentSpaceNormal
        let options: [MTKTextureLoader.Option : Any] = [ .generateMipmaps : wantMips ]
        
        
        texture = try? textureLoader.newTexture(texture: sourceTexture, options: options)
        
    }
    
    static func createBlankTexture(colour: [UInt8], device: MTLDevice) -> MTLTexture? {
        
        let bounds = MTLRegionMake2D(0, 0, 1, 1)
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm,
                                                                  width: bounds.size.width,
                                                                  height: bounds.size.height,
                                                                  mipmapped: false)
        descriptor.usage = .shaderRead
        let defaultTexture = device.makeTexture(descriptor: descriptor)!
        defaultTexture.replace(region: bounds, mipmapLevel: 0, withBytes: colour, bytesPerRow: 4)
        defaultTexture.label = "Blank Colour Texture"
        return defaultTexture
        
    }
    
    static func createBlankNormalMap(device: MTLDevice) -> MTLTexture? {
        
        let bounds = MTLRegionMake2D(0, 0, 1, 1)
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm,
                                                                  width: bounds.size.width,
                                                                  height: bounds.size.height,
                                                                  mipmapped: false)
        descriptor.usage = .shaderRead
        
        let defaultNormalMap = device.makeTexture(descriptor: descriptor)!
        let defaultNormal: [UInt8] = [127, 127, 255, 255] // Converts to (0, 0, 0, 1) in the shader after mapping to a normal
        defaultNormalMap.replace(region: bounds, mipmapLevel: 0, withBytes: defaultNormal, bytesPerRow: 4)
        defaultNormalMap.label = "Blank Normal Map"
        return defaultNormalMap
        
    }
    
    
    // As the names suggest, we call these when encoding commands
    func bindToVertexShader(encoder: MTLRenderCommandEncoder, index: Int) {
        encoder.setVertexTexture(texture, index: index)
    }
    
    func bindToFragmentShader(encoder: MTLRenderCommandEncoder, index: Int) {
        encoder.setFragmentTexture(texture, index: index)
    }
    
    func bindToComputeShader(encoder: MTLComputeCommandEncoder, index: Int) {
        encoder.setTexture(texture, index: index)
    }
    
    func bindToVertexShader(withDefault defaultTexture: MTLTexture?, encoder: MTLRenderCommandEncoder, index: Int) {
        encoder.setVertexTexture(texture ?? defaultTexture, index: index)
    }
    
    func bindToFragmentShader(withDefault defaultTexture: MTLTexture?, encoder: MTLRenderCommandEncoder, index: Int) {
        encoder.setFragmentTexture(texture ?? defaultTexture, index: index)
    }
    
    func bindToComputeShader(withDefault defaultTexture: MTLTexture?, encoder: MTLComputeCommandEncoder, index: Int) {
        encoder.setTexture(texture ?? defaultTexture, index: index)
    }
    
    
    static func createTextureLoader(device: MTLDevice) -> MTKTextureLoader {
        return MTKTextureLoader(device: device)
    }
    
}

struct Sampler {
    
    // This is really just straightforward
    let samplerState: MTLSamplerState?
    
    init(descriptor: MTLSamplerDescriptor, device: MTLDevice) {
        samplerState = device.makeSamplerState(descriptor: descriptor)
    }
    
    func bindToVertexShader(encoder: MTLRenderCommandEncoder, index: Int) {
        encoder.setVertexSamplerState(samplerState, index: index)
    }
    
    func bindToFragmentShader(encoder: MTLRenderCommandEncoder, index: Int) {
        encoder.setFragmentSamplerState(samplerState, index: index)
        
    }
    
    func bindToComputeShader(encoder: MTLComputeCommandEncoder, index: Int) {
        encoder.setSamplerState(samplerState, index: index)
    }
    
}

func createSamplerDescriptor() -> MTLSamplerDescriptor {
    // Configure the sampler
    let samplerDescriptor = MTLSamplerDescriptor()
    samplerDescriptor.sAddressMode = .repeat
    samplerDescriptor.tAddressMode = .repeat
    samplerDescriptor.minFilter = .linear
    samplerDescriptor.magFilter = .linear
    samplerDescriptor.mipFilter = .linear
    samplerDescriptor.label = "Texture Sampler"
    return samplerDescriptor
}


