//
//  Mesh.swift
//  MetalPBR
//
//  Created by Adil Patel on 14/09/2018.
//  Copyright © 2018 Adil Patel. All rights reserved.
//

import Foundation
import Metal
import MetalKit
import simd

struct TransparentIndex {
    
    var transparentSubmeshIndex: Int
    var alpha: Int
    
    init(mesh: MTKMesh, submeshIndex: Int, alpha: Int) {
        self.transparentSubmeshIndex = submeshIndex
        self.alpha = alpha
    }
    
}

/// This structure generates draw calls for a given `MTKMesh`.
struct Mesh {
    
    let mtkMesh: MTKMesh
    
    let vertexDescriptor: MTLVertexDescriptor?
    
    var opaqueSubmeshes = Array<Int>()
    
    var transparentSubmeshes = Array<TransparentIndex>()
    
    var hasTransparency = false
    
    init(name: String, meshGeometry: MeshGeometry, device: MTLDevice) {
        
        self.mtkMesh = meshGeometry.mtkMesh
        self.mtkMesh.name = name
        self.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(meshGeometry.vertexDescriptor)
        self.mtkMesh.vertexBuffers[0].buffer.label = name + " Vertex Buffer"
        
        for (i, submesh) in self.mtkMesh.submeshes.enumerated() {
            submesh.indexBuffer.buffer.label = name + " Index Buffer \(i)"
            opaqueSubmeshes.append(i)
        }
        
    }
    
    init(name: String, mtkMesh: MTKMesh, vertexDescriptor: MDLVertexDescriptor) {
        
        self.mtkMesh = mtkMesh
        self.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(vertexDescriptor)
        self.mtkMesh.vertexBuffers[0].buffer.label = name + " Vertex Buffer"
        
        for (i, submesh) in self.mtkMesh.submeshes.enumerated() {
            submesh.indexBuffer.buffer.label = name + " Index Buffer \(i)"
        }
        
    }
    
    // Assigns the vertex buffer to the vertex shader arguments
    func bindToVertexShader(encoder: MTLRenderCommandEncoder) {
        encoder.setVertexBuffer(mtkMesh.vertexBuffers[0].buffer, offset: mtkMesh.vertexBuffers[0].offset, index: BufferIndex.meshPositions.rawValue)
    }
    
    // Just a draw call for convenience
    func drawSubmesh(atIndex submeshIndex: Int, encoder: MTLRenderCommandEncoder) {
        
        let submesh = mtkMesh.submeshes[submeshIndex]
        encoder.drawIndexedPrimitives(type: submesh.primitiveType,
                                      indexCount: submesh.indexCount,
                                      indexType: submesh.indexType,
                                      indexBuffer: submesh.indexBuffer.buffer,
                                      indexBufferOffset: submesh.indexBuffer.offset)
        
        
        
    }
    
    
}
