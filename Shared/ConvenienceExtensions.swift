//
//  ConvenienceExtensions.swift
//  MetalPBR
//
//  Created by Adil Patel on 14/09/2018.
//  Copyright © 2018 Adil Patel. All rights reserved.
//

import CoreGraphics
import Foundation
import OSLog
import simd

nonisolated extension Logger {
    
    private static let subsystem = Bundle.main.bundleIdentifier ?? "MetalPBR"
    
    /// Messages relating to GPU setup and drawing
    static let renderer = Logger(subsystem: subsystem, category: "Renderer")
    
    /// Messages relating to loading meshes, textures, and materials
    static let resources = Logger(subsystem: subsystem, category: "Resources")
    
}

extension CGPoint {
    
    static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
    
    static func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
    
    static func += (lhs: inout CGPoint, rhs: CGPoint) {
        lhs = lhs + rhs
    }
    
    static func -= (lhs: inout CGPoint, rhs: CGPoint) {
        lhs = lhs - rhs
    }
    
}

// Note: `+=` and `-=` for floating-point SIMD vectors are now provided by the standard library.

extension SIMD4 where Scalar: SIMDScalar {
    
    var xyz: SIMD3<Scalar> {
        SIMD3<Scalar>(x, y, z)
    }
    
    init(_ threeVector: SIMD3<Scalar>, fourth: Scalar) {
        self.init(threeVector, fourth)
    }
    
}
