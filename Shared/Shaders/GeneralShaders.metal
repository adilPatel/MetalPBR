//
//  GeneralShaders.metal
//  MetalPBR
//
//  Created by Adil Patel on 27/11/2019.
//  Copyright © 2019 Adil Patel. All rights reserved.
//

#include <metal_stdlib>

#import "ShaderSupport.metal"

using namespace metal;

// ----- Skybox shaders -----

vertex SkyboxRasteriserData SkyboxVertexShader(uint vertexID [[vertex_id]],
                                               const device SkyboxVertex *vertices [[buffer(BufferIndexMeshPositions)]],
                                               constant SkyboxTransforms &transforms [[buffer(BufferIndexLocalUniforms)]]) {
    
    float3 position = float3(vertices[vertexID].position);
    
    SkyboxRasteriserData out;
    out.position = transforms.modelViewProjectionMatrix * float4(position, 1.0f);
    out.texCoord = position;
    
    return out;
    
}

fragment half4 SkyboxFragmentShader(SkyboxRasteriserData in [[stage_in]],
                                    texturecube<half, access::sample> texture,
                                    sampler samplerCube [[sampler(0)]]) {
    
    return texture.sample(samplerCube, in.texCoord);
    
}

// ----- Post-processing Shaders

constant half toneMapExposure = 1.0h;

vertex PostShaderRasteriserData PostProcessVertexShader(uint vertexID [[vertex_id]],
                                                        const device PostShaderVertex *vertices [[buffer(0)]]) {
    PostShaderVertex in = vertices[vertexID];
    PostShaderRasteriserData out;
    
    out.position = float4(float2(in.position), 0.0f, 1.0f);
    out.texCoord = float2(in.texCoord);
    return out;
}

half3 hableOperator(half3 col) {
    half A = 0.15h;
    half B = 0.50h;
    half C = 0.10h;
    half D = 0.20h;
    half E = 0.02h;
    half F = 0.30h;
    return ((col * (col * A + B * C) + D * E) / (col * (col * A + B) + D * F)) - E / F;
}

fragment half4 PostProcessFragmentShader(PostShaderRasteriserData in [[stage_in]],
                                         texture2d<half, access::sample> texture) {
    
    constexpr sampler sampler2d(min_filter::nearest,
                                mag_filter::nearest);
    
    half4 sampled = texture.sample(sampler2d, in.texCoord);
    half3 toneMapped = sampled.rgb * toneMapExposure * 4.0h;
    toneMapped = hableOperator(toneMapped) / hableOperator(half3(11.2h));
    
    return half4(toneMapped, 1.0h);
}

