//
//  ShaderSupport.metal
//  MetalPBR
//
//  Created by Adil Patel on 27/11/2019.
//  Copyright © 2019 Adil Patel. All rights reserved.
//

#include <metal_stdlib>
#include <simd/simd.h>


#import "ShaderTypes.h"

using namespace metal;

struct TransparentVertex {
    float3 position [[attribute(VertexAttributeVTPosition)]];
    float2 texCoords [[attribute(VertexAttributeVTTexcoord)]];
};

struct TransparentVertexOut {
    float4 position [[position]];
    half3 worldPos;
    float2 texCoords;
};

struct TransparentFragmentOut {
    half4 surface [[color(0), index(0)]];
    half4 transmittance [[color(0), index(1)]];
};

// The layout in the vertex array
struct Vertex {
    float3 position  [[attribute(VertexAttributeVNTTPosition)]];
    float3 normal    [[attribute(VertexAttributeVNTTNormal)]];
    float3 tangent   [[attribute(VertexAttributeVNTTTangent)]];
    float2 texCoords [[attribute(VertexAttributeVNTTTexcoord)]];
};

// The output of the vertex shader, which will be fed into the fragment shader
struct VertexOut {
    float4 position [[position]];
    float2 texCoords;
    half3 worldPos;
    half3 normal;
    half3 bitangent;
    half3 tangent;
};

// Convenience structure
struct LightingParameters {
    
    half3 lightDir;
    half3 viewDir;
    half3 halfVector;
    half3 reflectedVector;
    half3 normal;
    half3 reflectedcolour;
    half3 irradiatedcolour;
    half3 basecolour;
    half3 diffuseLightcolour;
    half  NdotH;
    half  NdotV;
    half  NdotL;
    half  HdotL;
    half  metalness;
    half  roughness;
    
};

typedef struct {
    float3 position;
} SkyboxVertex;

typedef struct {
    float4 position [[position]];
    float3 texCoord;
} SkyboxRasteriserData;

typedef struct {
    packed_float2 position;
    packed_float2 texCoord;
} PostShaderVertex;

typedef struct {
    float4 position [[position]];
    float2 texCoord;
} PostShaderRasteriserData;
