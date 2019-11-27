//
//  MosquitoScene.swift
//  MetalPBR
//
//  Created by Adil Patel on 12/07/2019.
//  Copyright © 2019 Adil Patel. All rights reserved.
//

import Foundation

struct MosquitoScene: Scene {
    
    var sceneResponder: SceneResponderDelegate!

    func sceneInit() {
        
        self.setOrbitCamera(withRadius: 2.0, azimuth: 0.0, elevation: .pi / 2.0, origin: Maths.originVector)
        
        let mosquitoMaterial = ResourceManager.createMaterial(baseColourName: "Mosquito Albedo",
                                                              ambientOcclusionName: nil,
                                                              metallicName: nil,
                                                              roughnessName: nil,
                                                              normalName: "Mosquito Normals",
                                                              emissiveName: nil)
        
        let amberMaterial = ResourceManager.createMaterial(baseColourName: "Amber Albedo",
                                                           ambientOcclusionName: "Amber AO",
                                                           metallicName: nil,
                                                           roughnessName: "Amber Roughness",
                                                           normalName: "Amber Normals",
                                                           emissiveName: nil)
        
        let mosquitoModel = ResourceManager.loadModel(fromFile: "Mosquito.obj")
        mosquitoModel.markSubmeshAsTransparent(atIndex: 2, alphaValue: 0)
        
        var materialArray = Array<Material>(repeating: mosquitoMaterial, count: 2)
        materialArray.append(amberMaterial)
        let mosquitoObject = GameObject(model: mosquitoModel, materials: materialArray)
        
        
        self.addToScene(object: mosquitoObject, position: Maths.originVector)
    }
    
}
