//
//  SceneAsset.swift
//  MetalPBR
//
//  Created by Adil Patel on 14/09/2018.
//  Copyright © 2018 Adil Patel. All rights reserved.
//

import Foundation
import Metal
import MetalKit
import ModelIO
import OSLog
import simd

enum MeshError: Error {
    case badVertexDescriptor
}

enum VertexLayout {
    case positionNormalTangentTexcoord
    case positionNormalTexcoord
    case positionNormal
    case positionTexcoord
}

/// This structure loads all meshes and textures from a given 3D scene file.
enum SceneAsset {
    
    static func createObjectsFromScene(name: String, url: URL, device: MTLDevice) -> [GameObject] {
        
        // Just like we did earlier, Model I/O loads MDLAssets using the buffer allocator
        let bufferAllocator = MTKMeshBufferAllocator(device: device)
        let asset = MDLAsset(url: url, vertexDescriptor: nil, bufferAllocator: bufferAllocator)
        
        // This will build all the associated textures with the mesh
        asset.loadTextures()
        
        let vertexDescriptor = VertexDescriptor.create(withLayout: .positionNormalTangentTexcoord)
        
        // Here we define the vertex layout and add the vertex descriptor
        for sourceMesh in asset.childObjects(of: MDLMesh.self).compactMap({ $0 as? MDLMesh }) {
            sourceMesh.addOrthTanBasis(forTextureCoordinateAttributeNamed: MDLVertexAttributeTextureCoordinate,
                                       normalAttributeNamed: MDLVertexAttributeNormal,
                                       tangentAttributeNamed: MDLVertexAttributeTangent)
            sourceMesh.vertexDescriptor = vertexDescriptor
        }
        
        // The tuple contains MDLMeshes and their corresponding MTKMeshes
        let sourceMeshes: [MDLMesh]
        let meshes: [MTKMesh]
        do {
            (sourceMeshes, meshes) = try MTKMesh.newMeshes(asset: asset, device: device)
        } catch {
            fatalError("Could not convert ModelIO meshes to MetalKit meshes: \(error)")
        }
        
        var nodes = [GameObject]()
        let textureLoader = Texture.createTextureLoader(device: device)
        
        // Get all materials from submeshes and create nodes from them
        for (sourceMesh, mtkMesh) in zip(sourceMeshes, meshes) {
            let submeshes = sourceMesh.submeshes?.compactMap { $0 as? MDLSubmesh } ?? []
            let materials = submeshes.map { Material(material: $0.material, textureLoader: textureLoader) }
            let mesh = Mesh(name: name, mtkMesh: mtkMesh, vertexDescriptor: vertexDescriptor)
            let node = GameObject(mesh: mesh, materials: materials)
            nodes.append(node)
        }
        
        return nodes
    }
    
    
    
}

/// This structure generates an `MTKMesh` from a supplied vertex descriptor.
struct MeshGeometry {
    
    var mtkMesh: MTKMesh!
    let vertexDescriptor: MDLVertexDescriptor!
    
    init(modelFile: String, layout: VertexLayout, device: MTLDevice) {
        
        // For now, we'll create all models the same
        vertexDescriptor = VertexDescriptor.create(withLayout: layout)
        
        // Create the URL for the model file
        guard let url = Bundle.main.url(forResource: modelFile, withExtension: nil) else {
            Logger.resources.error("Failed to find \(modelFile) in the bundle")
            return
        }
        
        // This is the same procedure as the other shapes
        let allocator = MTKMeshBufferAllocator(device: device)
        
        // Model I/O fetches an asset, which is a superclass for meshes, lights, and other stuff
        let asset = MDLAsset(url: url, vertexDescriptor: nil, bufferAllocator: allocator)
        
        guard let mdlMesh = asset.object(at: 0) as? MDLMesh else {
            Logger.resources.error("Failed to create mesh from \(modelFile)")
            return
        }
        
        // Calculate the tangent basis vectors if we're using tangents in the vertex descriptor...
        if layout == .positionNormalTangentTexcoord {
            mdlMesh.addTangentBasis(forTextureCoordinateAttributeNamed: MDLVertexAttributeTextureCoordinate,
                                    normalAttributeNamed: MDLVertexAttributeNormal,
                                    tangentAttributeNamed: MDLVertexAttributeTangent)
        }
        
        mdlMesh.vertexDescriptor = vertexDescriptor
        // And we construct our MTKMesh
        do {
            mtkMesh = try MTKMesh(mesh: mdlMesh, device: device)
        } catch {
            Logger.resources.error("Failed to allocate MetalKit mesh for \(modelFile): \(error)")
        }
        
    }
    
    init(sphereWithExtent extent: SIMD3<Float>,
         segments: SIMD2<UInt32>,
         layout: VertexLayout,
         device: MTLDevice) {
        
        // The "glue" between Model I/O and Metal
        let allocator = MTKMeshBufferAllocator(device: device)
        
        // Create the sphere mesh
        let mdlMesh = MDLMesh(sphereWithExtent: extent,
                              segments: segments,
                              inwardNormals: false,
                              geometryType: .triangles,
                              allocator: allocator)
        
        // Lay out the information in a vertex descriptor
        vertexDescriptor = VertexDescriptor.create(withLayout: layout)
        
        mdlMesh.vertexDescriptor = vertexDescriptor
        
        do {
            mtkMesh = try MTKMesh(mesh: mdlMesh, device: device)
        } catch {
            Logger.resources.error("Failed to create sphere: \(error)")
        }
        
    }
    
    init(boxWithExtent extent: SIMD3<Float>,
         segments: SIMD3<UInt32>,
         layout: VertexLayout,
         device: MTLDevice) {
        
        // The "glue" between Model I/O and Metal
        let allocator = MTKMeshBufferAllocator(device: device)
        
        let mdlMesh = MDLMesh(boxWithExtent: extent,
                              segments: segments,
                              inwardNormals: false,
                              geometryType: .triangles,
                              allocator: allocator)
        
        // Lay out the information in a vertex descriptor
        vertexDescriptor = VertexDescriptor.create(withLayout: layout)
        
        mdlMesh.vertexDescriptor = vertexDescriptor
        
        
        do {
            mtkMesh = try MTKMesh(mesh: mdlMesh, device: device)
        } catch {
            Logger.resources.error("Failed to create box: \(error)")
        }
        
    }
    
    init(planeWithExtent extent: SIMD3<Float>,
         segments: SIMD2<UInt32>,
         layout: VertexLayout,
         device: MTLDevice) {
        
        // The "glue" between Model I/O and Metal
        let allocator = MTKMeshBufferAllocator(device: device)
        
        let mdlMesh = MDLMesh(planeWithExtent: extent,
                              segments: segments,
                              geometryType: .triangles,
                              allocator: allocator)
        
        // Lay out the information in a vertex descriptor
        vertexDescriptor = VertexDescriptor.create(withLayout: layout)
        mdlMesh.vertexDescriptor = vertexDescriptor
        
        do {
            mtkMesh = try MTKMesh(mesh: mdlMesh, device: device)
        } catch {
            Logger.resources.error("Failed to create plane: \(error)")
        }
        
    }
    
    static let screenQuadArray: [Float32] = [
        
        1.0,  1.0,      1.0, 0.0,
        -1.0,  1.0,      0.0, 0.0,
        -1.0, -1.0,      0.0, 1.0,
        
        -1.0, -1.0,      0.0, 1.0,
        1.0, -1.0,      1.0, 1.0,
        1.0,  1.0,      1.0, 0.0
        
    ]
    
}

enum VertexDescriptor {
    
    static func create(withLayout layout: VertexLayout) -> MDLVertexDescriptor {
        switch layout {
        case .positionNormalTangentTexcoord:
            return createVNTTDescriptor()
        case .positionNormalTexcoord:
            return createVNTDescriptor()
        case .positionTexcoord:
            return createVTDescriptor()
        case .positionNormal:
            return createVNDescriptor()
        }
    }
    
    private static func createVNTTDescriptor() -> MDLVertexDescriptor {
        
        let vertexDescriptor = MDLVertexDescriptor()
        
        // Position
        var offset = 0
        vertexDescriptor.attributes[VertexAttributeVNTT.position.rawValue] = MDLVertexAttribute(name: MDLVertexAttributePosition,
                                                                                                format: .float3,
                                                                                                offset: offset,
                                                                                                bufferIndex: BufferIndex.meshPositions.rawValue)
        
        // Normal
        offset += MemoryLayout<SIMD3<Float>>.stride
        vertexDescriptor.attributes[VertexAttributeVNTT.normal.rawValue] = MDLVertexAttribute(name: MDLVertexAttributeNormal,
                                                                                              format: .float3,
                                                                                              offset: offset,
                                                                                              bufferIndex: BufferIndex.meshPositions.rawValue)
        
        // Tangent
        offset += MemoryLayout<SIMD3<Float>>.stride
        vertexDescriptor.attributes[VertexAttributeVNTT.tangent.rawValue] = MDLVertexAttribute(name: MDLVertexAttributeTangent,
                                                                                               format: .float3,
                                                                                               offset: offset,
                                                                                               bufferIndex: BufferIndex.meshPositions.rawValue)
        
        // Texture coordinate
        offset += MemoryLayout<SIMD3<Float>>.stride
        vertexDescriptor.attributes[VertexAttributeVNTT.texcoord.rawValue] = MDLVertexAttribute(name: MDLVertexAttributeTextureCoordinate,
                                                                                                format: .float2,
                                                                                                offset: offset,
                                                                                                bufferIndex: BufferIndex.meshPositions.rawValue)
        // Create the layout we desire
        offset += MemoryLayout<SIMD2<Float>>.stride
        vertexDescriptor.layouts[BufferIndex.meshPositions.rawValue] = MDLVertexBufferLayout(stride: offset)
        
        return vertexDescriptor
    }
    
    private static func createVNTDescriptor() -> MDLVertexDescriptor {
        
        let vertexDescriptor = MDLVertexDescriptor()
        
        // Position
        var offset = 0
        vertexDescriptor.attributes[VertexAttributeVNT.position.rawValue] = MDLVertexAttribute(name: MDLVertexAttributePosition,
                                                                                               format: .float3,
                                                                                               offset: offset,
                                                                                               bufferIndex: BufferIndex.meshPositions.rawValue)
        
        // Normal
        offset += MemoryLayout<SIMD3<Float>>.stride
        vertexDescriptor.attributes[VertexAttributeVNT.normal.rawValue] = MDLVertexAttribute(name: MDLVertexAttributeNormal,
                                                                                             format: .float3,
                                                                                             offset: offset,
                                                                                             bufferIndex: BufferIndex.meshPositions.rawValue)
        
        // Texture coordinate
        offset += MemoryLayout<SIMD3<Float>>.stride
        vertexDescriptor.attributes[VertexAttributeVNT.texcoord.rawValue] = MDLVertexAttribute(name: MDLVertexAttributeTextureCoordinate,
                                                                                               format: .float2,
                                                                                               offset: offset,
                                                                                               bufferIndex: BufferIndex.meshPositions.rawValue)
        // Create the layout we desire
        offset += MemoryLayout<SIMD2<Float>>.stride
        vertexDescriptor.layouts[BufferIndex.meshPositions.rawValue] = MDLVertexBufferLayout(stride: offset)
        
        return vertexDescriptor
    }
    
    private static func createVTDescriptor() -> MDLVertexDescriptor {
        
        let vertexDescriptor = MDLVertexDescriptor()
        
        // Position
        var offset = 0
        vertexDescriptor.attributes[VertexAttributeVT.position.rawValue] = MDLVertexAttribute(name: MDLVertexAttributePosition,
                                                                                              format: .float3,
                                                                                              offset: offset,
                                                                                              bufferIndex: BufferIndex.meshPositions.rawValue)
        
        // Texture coordinate
        offset += MemoryLayout<SIMD3<Float>>.stride
        vertexDescriptor.attributes[VertexAttributeVT.texcoord.rawValue] = MDLVertexAttribute(name: MDLVertexAttributeTextureCoordinate,
                                                                                              format: .float2,
                                                                                              offset: offset,
                                                                                              bufferIndex: BufferIndex.meshPositions.rawValue)
        // Create the layout we desire
        offset += MemoryLayout<SIMD2<Float>>.stride
        vertexDescriptor.layouts[BufferIndex.meshPositions.rawValue] = MDLVertexBufferLayout(stride: offset)
        
        return vertexDescriptor
        
    }
    
    private static func createVNDescriptor() -> MDLVertexDescriptor {
        
        let vertexDescriptor = MDLVertexDescriptor()
        
        // Position
        var offset = 0
        vertexDescriptor.attributes[VertexAttributeVN.position.rawValue] = MDLVertexAttribute(name: MDLVertexAttributePosition,
                                                                                              format: .float3,
                                                                                              offset: offset,
                                                                                              bufferIndex: BufferIndex.meshPositions.rawValue)
        
        // Normal
        offset += MemoryLayout<SIMD3<Float>>.stride
        vertexDescriptor.attributes[VertexAttributeVN.normal.rawValue] = MDLVertexAttribute(name: MDLVertexAttributeNormal,
                                                                                            format: .float3,
                                                                                            offset: offset,
                                                                                            bufferIndex: BufferIndex.meshPositions.rawValue)
        // Create the layout we desire
        offset += MemoryLayout<SIMD3<Float>>.stride
        vertexDescriptor.layouts[BufferIndex.meshPositions.rawValue] = MDLVertexBufferLayout(stride: offset)
        
        return vertexDescriptor
        
    }
}
