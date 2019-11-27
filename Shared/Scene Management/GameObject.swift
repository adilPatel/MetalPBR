//
//  GameObject.swift
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

/// This holds the geometry and material data for an entity in a scene.
struct GameObject {
    
    let mesh: Mesh
    
    let materials: [Material]
    
    init(mesh: Mesh, materials: [Material]) {
        self.mesh = mesh
        self.materials = materials
    }
    
    init(model: Model, materials: [Material]) {
        self.mesh = model.mesh
        self.materials = materials
    }
    
    func draw(usingEncoder encoder: MTLRenderCommandEncoder, constantBufferOffset offset: Int) {
        
        mesh.bindToVertexShader(encoder: encoder)
        encoder.setVertexBufferOffset(offset, index: BufferIndex.localUniforms.rawValue)
        
        for (i, _) in materials.enumerated() {
            materials[i].bindTexturesToShader(encoder: encoder)
            mesh.drawSubmesh(atIndex: i, encoder: encoder)
        }
        
    }
    
    func drawOpaqueSubmeshes(atSubmeshIndex submeshIndex: Int, usingEncoder encoder: MTLRenderCommandEncoder, constantBufferOffset offset: Int) {
        
        mesh.bindToVertexShader(encoder: encoder)
        encoder.setVertexBufferOffset(offset, index: BufferIndex.localUniforms.rawValue)
        
        for i in mesh.opaqueSubmeshes {
            materials[i].bindTexturesToShader(encoder: encoder)
            mesh.drawSubmesh(atIndex: i, encoder: encoder)
        }
        
    }
    
    func drawTransparentSubmeshes(usingEncoder encoder: MTLRenderCommandEncoder, constantBufferOffset offset: Int) {
        
        mesh.bindToVertexShader(encoder: encoder)
        encoder.setVertexBufferOffset(offset, index: BufferIndex.localUniforms.rawValue)
        
        for index in mesh.transparentSubmeshes {
            materials[index.transparentSubmeshIndex].bindAlbedoToShader(encoder: encoder)
            mesh.drawSubmesh(atIndex: index.transparentSubmeshIndex, encoder: encoder)
        }
        
    }
    
    
    func draw(atSubmeshIndex submeshIndex: Int, usingEncoder encoder: MTLRenderCommandEncoder, constantBufferOffset offset: Int) {
        
        mesh.bindToVertexShader(encoder: encoder)
        encoder.setVertexBufferOffset(offset, index: BufferIndex.localUniforms.rawValue)
        
        
        
        materials[submeshIndex].bindTexturesToShader(encoder: encoder)
        mesh.drawSubmesh(atIndex: submeshIndex, encoder: encoder)
        
        
    }
    
}

