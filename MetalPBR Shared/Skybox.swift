//
//  Skybox.swift
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

/// This structure handles the generation and drawing of the skybox.
struct Skybox {
    
    private var mtkMesh: MTKMesh!
    var texture: MTLTexture?
    var sampler: Sampler!
    var pipelineState: MTLRenderPipelineState!
    var depthStencilState: MTLDepthStencilState!
    
    init(device: MTLDevice,
         vertexFunction: MTLFunction?,
         fragmentFunction: MTLFunction?,
         colourPixelFormat: MTLPixelFormat,
         depthStencilPixelFormat: MTLPixelFormat) {
        
        // First we generate the mesh
        let allocator = MTKMeshBufferAllocator(device: device)
        
        let mdlMesh = MDLMesh(boxWithExtent: SIMD3<Float>(50.0, 50.0, 50.0),
                              segments: SIMD3<UInt32>(1, 1, 1),
                              inwardNormals: true,
                              geometryType: .triangles,
                              allocator: allocator)
        
        let vertexDescriptor = createVertexDescriptor()
        let mdlVertexDescriptor = MTKModelIOVertexDescriptorFromMetal(vertexDescriptor)
        guard let attributes = mdlVertexDescriptor.attributes as? [MDLVertexAttribute] else {
            return
        }
        
        attributes[0].name = MDLVertexAttributePosition
        mdlMesh.vertexDescriptor = mdlVertexDescriptor
        
        do {
            try mtkMesh = MTKMesh(mesh: mdlMesh, device: device)
        } catch {
            print("ERROR: Failed to create skybox with error:\n\(error)")
            return
        }
        
        // Now we allocate the cubemap texture and sampler
        texture = createTexture(device: device)
        sampler = createSkyboxSampler(device: device)
        
        pipelineState = createRenderPipelineState(device: device,
                                                  vertexFunction: vertexFunction,
                                                  fragmentFunction: fragmentFunction,
                                                  vertexDescriptor: vertexDescriptor,
                                                  colourPixelFormat: colourPixelFormat,
                                                  depthStencilPixelFormat: depthStencilPixelFormat)
        
        
        // The depth stencil state requires special treatment
        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.isDepthWriteEnabled = false
        depthStencilDescriptor.depthCompareFunction = .always
        depthStencilDescriptor.label = "Skybox Depth Stencil State"
        guard let state = device.makeDepthStencilState(descriptor: depthStencilDescriptor) else {
            return
        }
        depthStencilState = state
        
    }
    
    func draw(encoder: MTLRenderCommandEncoder, constants: SkyboxTransforms) {
        
        // Sets our unique pipeline and depth states
        encoder.pushDebugGroup("Setting the Skybox Render and Depth States")
        encoder.setRenderPipelineState(pipelineState)
        encoder.setDepthStencilState(depthStencilState)
        encoder.popDebugGroup()
        
        // Simple to draw the skybox as its one object with simple constants
        var transforms = constants
        encoder.pushDebugGroup("Setting the Skybox Vertex Arguments")
        encoder.setVertexBuffer(mtkMesh.vertexBuffers[0].buffer,
                                offset: 0,
                                index: BufferIndex.meshPositions.rawValue)
        encoder.setVertexBytes(&transforms,
                               length: MemoryLayout<SkyboxTransforms>.stride,
                               index: BufferIndex.localUniforms.rawValue)
        encoder.popDebugGroup()
        
        encoder.pushDebugGroup("Setting the Skybox Fragment Arguments")
        encoder.setFragmentTexture(texture, index: 0)
        encoder.setFragmentSamplerState(sampler.samplerState, index: 0)
        encoder.popDebugGroup()
        
        encoder.pushDebugGroup("Drawing the Sky")
        encoder.drawIndexedPrimitives(type: mtkMesh.submeshes[0].primitiveType,
                                      indexCount: mtkMesh.submeshes[0].indexCount,
                                      indexType: mtkMesh.submeshes[0].indexType,
                                      indexBuffer: mtkMesh.submeshes[0].indexBuffer.buffer,
                                      indexBufferOffset: 0)
        encoder.popDebugGroup()
    }
    
    private func createRenderPipelineState(device: MTLDevice,
                                           vertexFunction: MTLFunction?,
                                           fragmentFunction: MTLFunction?,
                                           vertexDescriptor: MTLVertexDescriptor,
                                           colourPixelFormat: MTLPixelFormat,
                                           depthStencilPixelFormat: MTLPixelFormat) -> MTLRenderPipelineState {
        
        // The difference here is that we're using different shaders and a different vertex descriptor
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.sampleCount = sampleCount
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = colourPixelFormat
        pipelineDescriptor.depthAttachmentPixelFormat = depthStencilPixelFormat
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        
        var pipelineState: MTLRenderPipelineState!
        do {
            try pipelineState = device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            print("ERROR: Could not create skybox pipeline state with error:\n\(error)")
        }
        
        return pipelineState
    }
    
    private func createVertexDescriptor() -> MTLVertexDescriptor {
        
        let vertexDescriptor = MTLVertexDescriptor()
        
        // Position
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = BufferIndex.meshPositions.rawValue
        
        // Interleave them
        vertexDescriptor.layouts[0].stepRate = 1
        vertexDescriptor.layouts[0].stepFunction = .perVertex
        vertexDescriptor.layouts[0].stride = MemoryLayout<SIMD3<Float>>.stride
        
        return vertexDescriptor
        
    }
    
    private func createSkyboxSampler(device: MTLDevice) -> Sampler {
        
        // We don't really have to worry much about minification as each pixel
        // will always be very far away from the camera. We'll also disable
        // trilinear filtering to eliminate the unnecessary fragment shader
        // overhead
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.sAddressMode = .repeat
        samplerDescriptor.tAddressMode = .repeat
        samplerDescriptor.minFilter = .nearest
        samplerDescriptor.magFilter = .linear
        samplerDescriptor.mipFilter = .nearest
        samplerDescriptor.label = "Skybox Texture Sampler"
        
        return Sampler(descriptor: samplerDescriptor, device: device)
    }
    
    private func createTexture(device: MTLDevice) -> MTLTexture? {
        
        // There's a fixed set of options for this texture
        let storageMode = NSNumber(value: MTLStorageMode.`private`.rawValue)
        let textureUsage = NSNumber(value: MTLTextureUsage.shaderRead.rawValue)
        
        let options = [MTKTextureLoader.Option.textureStorageMode : storageMode,
                       MTKTextureLoader.Option.textureUsage : textureUsage]
        
        let textureLoader = MTKTextureLoader(device: device)
        
        var texture: MTLTexture?
        
        do {
            try texture = textureLoader.newTexture(name: "River Skybox",
                                                   scaleFactor: 1.0,
                                                   bundle: nil,
                                                   options: options)
        } catch {
            print("ERROR: Failed to create skybox with error: \(error)")
        }
        
        
        return texture
        
    }
    
}
