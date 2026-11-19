//
//  Maths.swift
//  MetalPBR
//
//  Created by Adil Patel on 14/09/2018.
//  Copyright © 2018 Adil Patel. All rights reserved.
//

import Foundation
import simd

/// A namespace for the matrix and angle helpers used throughout the renderer.
enum Maths {
    
    static var originVector: SIMD3<Float> {
        .zero
    }
    
    static func createAxisRotation(radians: Float, axis: SIMD3<Float>) -> float4x4 {
        
        let s = sin(radians)
        let c = cos(radians)
        let k = 1.0 - c
        
        let x = axis.x, y = axis.y, z = axis.z
        
        return float4x4(rows: [
            SIMD4<Float>(x*x*k + c,   x*y*k - z*s, x*z*k + y*s, 0.0),
            SIMD4<Float>(x*y*k + z*s, y*y*k + c,   y*z*k - x*s, 0.0),
            SIMD4<Float>(x*z*k - y*s, y*z*k + x*s, z*z*k + c,   0.0),
            SIMD4<Float>(0.0, 0.0, 0.0, 1.0)
        ])
        
    }
    
    static func createXRotation(radians: Float) -> float4x4 {
        let s = sin(radians)
        let c = cos(radians)
        
        return float4x4(rows: [
            SIMD4<Float>(1.0, 0.0, 0.0, 0.0),
            SIMD4<Float>(0.0, c,   -s,  0.0),
            SIMD4<Float>(0.0, s,    c,  0.0),
            SIMD4<Float>(0.0, 0.0, 0.0, 1.0)
        ])
    }
    
    static func createYRotation(radians: Float) -> float4x4 {
        let s = sin(radians)
        let c = cos(radians)
        
        return float4x4(rows: [
            SIMD4<Float>(c,   0.0, -s,  0.0),
            SIMD4<Float>(0.0, 1.0, 0.0, 0.0),
            SIMD4<Float>(s,   0.0, c,   0.0),
            SIMD4<Float>(0.0, 0.0, 0.0, 1.0)
        ])
    }
    
    static func createZRotation(radians: Float) -> float4x4 {
        let s = sin(radians)
        let c = cos(radians)
        
        return float4x4(rows: [
            SIMD4<Float>(c,   -s,  0.0, 0.0),
            SIMD4<Float>(s,   c,   0.0, 0.0),
            SIMD4<Float>(0.0, 0.0, 1.0, 0.0),
            SIMD4<Float>(0.0, 0.0, 0.0, 1.0)
        ])
    }
    
    static func createCameraRotation(altitude: Float, azimuth: Float) -> float4x4 {
        
        // Now we rotate about the y axis
        let azimRotation = Maths.createYRotation(radians: azimuth)
        
        // AHHH CREATES PROBLEMS WHEN THE CAMERA IS ALONG THE X AXIS!
        let altRotation = Maths.createXRotation(radians: altitude)
        
        return altRotation * azimRotation
        
    }
    
    static func createTranslationMatrix(vector: SIMD3<Float>) -> float4x4 {
        
        float4x4(rows: [
            SIMD4<Float>(1.0, 0.0, 0.0, vector.x),
            SIMD4<Float>(0.0, 1.0, 0.0, vector.y),
            SIMD4<Float>(0.0, 0.0, 1.0, vector.z),
            SIMD4<Float>(0.0, 0.0, 0.0, 1.0)
        ])
        
    }
    
    static func createProjectionMatrix(fovy: Float, aspectRatio: Float, nearZ: Float, farZ: Float) -> float4x4 {
        
        let ys = 1 / tan(0.5 * fovy)
        let xs = ys / aspectRatio
        let zs = farZ / (nearZ - farZ)
        
        return float4x4(rows: [
            SIMD4<Float>(xs, 0.0, 0.0, 0.0),
            SIMD4<Float>(0.0, ys, 0.0, 0.0),
            SIMD4<Float>(0.0, 0.0, zs, zs * nearZ),
            SIMD4<Float>(0.0, 0.0, -1.0, 0.0)
        ])
        
    }
    
    static func createNormalMatrix(fromMVMatrix matrix: float4x4) -> float3x3 {
        createMatrix3x3UpperLeft(matrix: matrix).inverse.transpose
    }
    
    static func createMatrix3x3UpperLeft(matrix: float4x4) -> float3x3 {
        let (c0, c1, c2, _) = matrix.columns
        return float3x3(columns: (c0.xyz, c1.xyz, c2.xyz))
    }
    
    static func radiansToDegrees(radians: Float) -> Float {
        radians * 180.0 / .pi
    }
    
    static func degreesToRadians(degrees: Float) -> Float {
        degrees * .pi / 180.0
    }
    
}
