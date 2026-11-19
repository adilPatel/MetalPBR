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
import OSLog

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
        let options: [MTKTextureLoader.Option: Any] = [
            .generateMipmaps: createMipMaps,
            .allocateMipmaps: createMipMaps,
            .textureStorageMode: textureStorage.rawValue,
            .textureUsage: usage.rawValue,
            .textureCPUCacheMode: cpuCacheMode.rawValue
        ]
        
        self.init(name: name, file: file, options: options, device: device)
        
    }
    
    init(name: String, file: String, options: [MTKTextureLoader.Option: Any], device: MTLDevice) {
        
        let textureLoader = Texture.createTextureLoader(device: device)
        
        // Load the file
        guard let url = Bundle.main.url(forResource: file, withExtension: nil) else {
            Logger.resources.error("Failed to find \(file) in the bundle")
            return
        }
        do {
            texture = try textureLoader.newTexture(URL: url, options: options)
            texture?.label = name
        } catch {
            Logger.resources.error("Failed to create \(name) texture with error: \(error)")
        }
        
    }
    
    init(fromAssetCatalogueNamed name: String, usage: MTLTextureUsage, storageMode: MTLStorageMode, device: MTLDevice) {
        
        // These are simpler because mip-mapping is handled in the asset catalogue
        let options: [MTKTextureLoader.Option: Any] = [
            .textureStorageMode: storageMode.rawValue,
            .textureUsage: usage.rawValue
        ]
        
        self.init(fromAssetCatalogueNamed: name, options: options, device: device)
        
    }
    
    init(fromAssetCatalogueNamed name: String, options: [MTKTextureLoader.Option: Any], device: MTLDevice) {
        
        // This is even simpler than the above
        let textureLoader = Texture.createTextureLoader(device: device)
        
        do {
            texture = try textureLoader.newTexture(name: name,
                                                   scaleFactor: 1.0,
                                                   bundle: nil,
                                                   options: options)
            texture?.label = name
        } catch {
            Logger.resources.error("Failed to create \(name) texture from the asset catalogue with error: \(error)")
        }
        
    }
    
    init(for semantic: MDLMaterialSemantic, in material: MDLMaterial?, textureLoader: MTKTextureLoader) {
        
        // It grabs a material property (like roughness) from the source texture
        guard let materialProperty = material?.property(with: semantic),
              let sourceTexture = materialProperty.textureSamplerValue?.texture else { return }
        
        // We aren't mip-mapping the tangent space normals
        let wantMips = materialProperty.semantic != .tangentSpaceNormal
        let options: [MTKTextureLoader.Option: Any] = [
            .generateMipmaps: wantMips,
            .textureStorageMode: MTLStorageMode.private.rawValue,
            .textureUsage: MTLTextureUsage.shaderRead.rawValue
        ]
        
        texture = try? textureLoader.newTexture(texture: sourceTexture, options: options)
        
    }
    
    static func createBlankTexture(colour: [UInt8], device: MTLDevice) -> MTLTexture? {
        createSinglePixelTexture(bytes: colour, label: "Blank Colour Texture", device: device)
    }
    
    static func createBlankNormalMap(device: MTLDevice) -> MTLTexture? {
        // Converts to (0, 0, 1) in the shader after mapping to a normal
        createSinglePixelTexture(bytes: [127, 127, 255, 255], label: "Blank Normal Map", device: device)
    }
    
    /// Creates a 1x1 RGBA8 texture filled with the supplied pixel
    private static func createSinglePixelTexture(bytes: [UInt8], label: String, device: MTLDevice) -> MTLTexture? {
        
        let bounds = MTLRegionMake2D(0, 0, 1, 1)
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm,
                                                                  width: bounds.size.width,
                                                                  height: bounds.size.height,
                                                                  mipmapped: false)
        descriptor.usage = .shaderRead
        guard let texture = device.makeTexture(descriptor: descriptor) else {
            Logger.resources.error("Failed to allocate \(label)")
            return nil
        }
        texture.replace(region: bounds, mipmapLevel: 0, withBytes: bytes, bytesPerRow: 4)
        texture.label = label
        return texture
        
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
        MTKTextureLoader(device: device)
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
