//
//  Model.swift
//  MetalPBR
//
//  Created by Adil Patel on 08/07/2019.
//  Copyright © 2019 Adil Patel. All rights reserved.
//

import Foundation
import Metal

/// A high-level representation of the geometry (mesh) of an object.
class Model {
    
    var mesh: Mesh!
    
    var name: String
    
    var submeshCount: Int {
        return mesh.mtkMesh.submeshes.count
    }
    
    init(fromFile name: String, device: MTLDevice) {
        
        let meshGeometry = MeshGeometry(modelFile: name, layout: .positionNormalTangentTexcoord, device: device)
        self.name = name.components(separatedBy: ".")[0]
        
        mesh = Mesh(name: self.name, meshGeometry: meshGeometry, device: device)
                
    }
    
    func markSubmeshAsTransparent(atIndex index: Int, alphaValue alpha: Int) {
        
        mesh.transparentSubmeshes.append(TransparentIndex(mesh: mesh.mtkMesh, submeshIndex: index, alpha: alpha))
        mesh.hasTransparency = true
        mesh.opaqueSubmeshes.remove(at: index)
        
    }
    

    
    
}
