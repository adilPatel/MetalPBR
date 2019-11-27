//
//  ConvenienceExtensions.swift
//  MetalPBR
//
//  Created by Adil Patel on 14/09/2018.
//  Copyright © 2018 Adil Patel. All rights reserved.
//

import Foundation
import simd

#if os(OSX)
import Cocoa
#else
import UIKit
#endif

extension CGPoint {
    
    static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        let x = lhs.x + rhs.x
        let y = lhs.y + rhs.y
        return CGPoint(x: x, y: y)
    }
    
    static func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        let dx = lhs.x - rhs.x
        let dy = lhs.y - rhs.y
        return CGPoint(x: dx, y: dy)
    }
    
    static func += (lhs: inout CGPoint, rhs: CGPoint) {
        lhs.x += rhs.x
        lhs.y += rhs.y
    }
    
    static func -= (lhs: inout CGPoint, rhs: CGPoint) {
        lhs.x -= rhs.x
        lhs.y -= rhs.y
    }
    
}

extension SIMD3 where Scalar : FloatingPoint {
    
    static func += (lhs: inout SIMD3<Scalar>, rhs: SIMD3<Scalar>) {
        lhs = lhs + rhs
    }
    
    static func -= (lhs: inout SIMD3<Scalar>, rhs: SIMD3<Scalar>) {
        lhs = lhs - rhs
    }

}

extension SIMD4 where Scalar : SIMDScalar {
    
    var xyz: SIMD3<Scalar> {
        return SIMD3<Scalar>(self.x, self.y, self.z)
    }
    
    init(_ threeVector: SIMD3<Scalar>, fourth: Scalar) {
        self.init(threeVector.x, threeVector.y, threeVector.z, fourth)
    }
    
}

extension SIMD4 where SIMD4.Scalar : FloatingPoint {
    
    static func += (lhs: inout SIMD4<Scalar>, rhs: SIMD4<Scalar>) {
        lhs = lhs + rhs
    }
    
    static func -= (lhs: inout SIMD4<Scalar>, rhs: SIMD4<Scalar>) {
        lhs = lhs - rhs
    }
    
}
