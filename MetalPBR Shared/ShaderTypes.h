//
//  ShaderTypes.h
//  MetalPBR Shared
//
//  Created by Adil Patel on 14/09/2018.
//  Copyright © 2018 Adil Patel. All rights reserved.
//

//
//  Header containing types and enum constants shared between Metal shaders and Swift/ObjC source
//
#ifndef ShaderTypes_h
#define ShaderTypes_h

#ifdef __METAL_VERSION__
#define NS_ENUM(_type, _name) enum _name : _type _name; enum _name : _type
#define NSInteger metal::int32_t
#else
#import <Foundation/Foundation.h>
#endif

#include <simd/simd.h>

typedef NS_ENUM(NSInteger, BufferIndex) {
    BufferIndexMeshPositions     = 0,
    BufferIndexLocalUniforms     = 1,
    BufferIndexPerFrameConstants = 2,
};

typedef NS_ENUM(NSInteger, VertexAttributeVNTT) {
    VertexAttributeVNTTPosition = 0,
    VertexAttributeVNTTNormal   = 1,
    VertexAttributeVNTTTangent  = 2,
    VertexAttributeVNTTTexcoord = 3,
};

typedef NS_ENUM(NSInteger, VertexAttributeVNT) {
    VertexAttributeVNTPosition = 0,
    VertexAttributeVNTNormal   = 1,
    VertexAttributeVNTTexcoord = 2,
};

typedef NS_ENUM(NSInteger, VertexAttributeVT) {
    VertexAttributeVTPosition = 0,
    VertexAttributeVTTexcoord = 1,
};

typedef NS_ENUM(NSInteger, VertexAttributeVN) {
    VertexAttributeVNPosition = 0,
    VertexAttributeVNNormal   = 1,
};

typedef NS_ENUM(NSInteger, TextureIndex) {
    TextureIndexAlbedo     = 0,
    TextureIndexAO         = 1,
    TextureIndexEmissive   = 2,
    TextureIndexMetallic   = 3,
    TextureIndexNormal     = 4,
    TextureIndexRoughness  = 5,
    TextureIndexIrradiance = 6,
};

typedef struct {
    matrix_float4x4 modelViewMatrix;
    matrix_float3x3 normalMatrix;
    matrix_float4x4 pad1;
    matrix_float4x4 pad2;
    matrix_float4x4 pad3;
} ObjectTransforms;

typedef struct {
    matrix_float4x4 modelViewProjectionMatrix;
} SkyboxTransforms;

typedef struct {
    matrix_float4x4 projectionMatrix;
    vector_float3 cameraPosition;
    vector_float3 pad1;
    vector_float3 pad2;
    vector_float3 pad3;
    matrix_float4x4 pad4;
    matrix_float4x4 pad5;
    
} PerFrameConstants;

#endif /* ShaderTypes_h */
