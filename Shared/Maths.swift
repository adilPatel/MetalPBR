//
//  Maths.swift
//  MetalPBR
//
//  Created by Adil Patel on 14/09/2018.
//  Copyright © 2018 Adil Patel. All rights reserved.
//

import Foundation
import simd

struct Maths {
    
    static var originVector: SIMD3<Float> {
        return SIMD3<Float>(0.0, 0.0, 0.0)
    }
    
    static func createAxisRotation(radians: Float, axis: SIMD3<Float>) -> float4x4 {
        
        let s = sinf(radians)
        let c = cosf(radians)
        let k = 1.0 - c
        
        let x = axis.x, y = axis.y, z = axis.z
        
        let row1 = SIMD4<Float>(x*x*k + c,   x*y*k - z*s, x*z*k + y*s, 0.0)
        let row2 = SIMD4<Float>(x*y*k + z*s, y*y*k + c,   y*z*k - x*s, 0.0)
        let row3 = SIMD4<Float>(x*z*k - y*s, y*z*k + x*s, z*z*k + c,   0.0)
        let row4 = SIMD4<Float>(0.0, 0.0, 0.0, 1.0)
        
        return matrix_from_rows(row1, row2, row3, row4)
        
    }
    
    static func createXRotation(radians: Float) -> float4x4 {
        let s = sinf(radians)
        let c = cosf(radians)
        
        let row1 = SIMD4<Float>(1.0, 0.0, 0.0, 0.0)
        let row2 = SIMD4<Float>(0.0, c,   -s,  0.0)
        let row3 = SIMD4<Float>(0.0, s,    c,  0.0)
        let row4 = SIMD4<Float>(0.0, 0.0, 0.0, 1.0)
        
        return matrix_from_rows(row1, row2, row3, row4)
    }
    
    static func createYRotation(radians: Float) -> float4x4 {
        let s = sinf(radians)
        let c = cosf(radians)
        
        let row1 = SIMD4<Float>(c,   0.0, -s,   0.0)
        let row2 = SIMD4<Float>(0.0, 1.0, 0.0, 0.0)
        let row3 = SIMD4<Float>( s, 0.0, c,   0.0)
        let row4 = SIMD4<Float>(0.0, 0.0, 0.0, 1.0)
        
        return matrix_from_rows(row1, row2, row3, row4)
    }
    
    static func createZRotation(radians: Float) -> float4x4 {
        let s = sinf(radians)
        let c = cosf(radians)
        
        let row1 = SIMD4<Float>(c,   -s,  0.0, 0.0)
        let row2 = SIMD4<Float>(s,   c,   0.0, 0.0)
        let row3 = SIMD4<Float>(0.0, 0.0, 1.0, 0.0)
        let row4 = SIMD4<Float>(0.0, 0.0, 0.0, 1.0)
        
        return matrix_from_rows(row1, row2, row3, row4)
    }
    
    static func createCameraRotation(altitude: Float, azimuth: Float) -> float4x4 {
        
        // Now we rotate about the y axis
        let azimRotation = Maths.createYRotation(radians: azimuth)
        
        // AHHH CREATES PROBLEMS WHEN THE CAMERA IS ALONG THE X AXIS!
        let altRotation = Maths.createXRotation(radians: altitude)
        
        return altRotation * azimRotation
        
    }
    
    static func createTranslationMatrix(vector: SIMD3<Float>) -> float4x4 {
        
        let row1 = SIMD4<Float>(1.0, 0.0, 0.0, vector.x)
        let row2 = SIMD4<Float>(0.0, 1.0, 0.0, vector.y)
        let row3 = SIMD4<Float>(0.0, 0.0, 1.0, vector.z)
        let row4 = SIMD4<Float>(0.0, 0.0, 0.0, 1.0)
        
        return matrix_from_rows(row1, row2, row3, row4)
        
    }
    
    static func createProjectionMatrix(fovy: Float, aspectRatio: Float, nearZ: Float, farZ: Float) -> float4x4 {
        
        let ys = 1 / tanf(0.5 * fovy)
        let xs = ys / aspectRatio
        let zs = farZ / (nearZ - farZ)
        
        let r1 = SIMD4<Float>(xs, 0.0, 0.0, 0.0)
        let r2 = SIMD4<Float>(0.0, ys, 0.0, 0.0)
        let r3 = SIMD4<Float>(0.0, 0.0, zs, zs * nearZ)
        let r4 = SIMD4<Float>(0.0, 0.0, -1.0, 0.0)
        
        return matrix_from_rows(r1, r2, r3, r4)
        
    }
    
    static func createNormalMatrix(fromMVMatrix matrix: float4x4) -> float3x3 {
        let upperleft = createMatrix3x3UpperLeft(matrix: matrix)
        return (upperleft.inverse).transpose
    }
    
    static func createMatrix3x3UpperLeft(matrix: float4x4) -> float3x3 {
        
        let (inCol1, inCol2, inCol3, _) = matrix.columns
        let row1 = SIMD3<Float>(inCol1[0], inCol2[0], inCol3[0])
        let row2 = SIMD3<Float>(inCol1[1], inCol2[1], inCol3[1])
        let row3 = SIMD3<Float>(inCol1[2], inCol2[2], inCol3[2])
        
        return matrix_from_rows(row1, row2, row3)
    }
    
    static func radiansToDegrees(radians: Float) -> Float {
        return radians * 180.0 / .pi
    }
    
    static func degreesToRadians(degrees: Float) -> Float {
        return degrees * .pi / 180.0
    }
    
}



