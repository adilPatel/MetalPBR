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


// ----- Transparency Shaders -----

vertex TransparentVertexOut transparencyVertexShader(Vertex in [[stage_in]],
                                                  constant ObjectTransforms &uniforms [[buffer(BufferIndexLocalUniforms)]],
                                                  constant PerFrameConstants &frameConstants [[buffer(BufferIndexPerFrameConstants)]]) {
    
    half3 position = half3(in.position);
    
    half4 transformedPos = half4(position, 1.0h);
    transformedPos = half4x4(uniforms.modelViewMatrix) * transformedPos;
    
    half4 projected = half4x4(frameConstants.projectionMatrix) * transformedPos;
    
    TransparentVertexOut out;
    out.position = float4(projected);
    out.worldPos = half3(transformedPos);
    out.texCoords = in.texCoords;
    
    return out;
}

fragment half4 backfaceFragmentShader(TransparentVertexOut in [[stage_in]],
                                      texture2d<float> materialColour [[texture(TextureIndexAlbedo)]]) {
    
    constexpr sampler sampler2d(min_filter::nearest,
                                mag_filter::nearest);
    
    float2 texCoord = in.texCoords;
    float4 sampled = materialColour.sample(sampler2d, texCoord);
    
    return half4(half3(sampled.rgb), 0.5h);
    
}

fragment TransparentFragmentOut frontfaceFragmentShader(TransparentVertexOut in [[stage_in]],
                                                        constant PerFrameConstants &uniforms [[buffer(BufferIndexPerFrameConstants)]],
                                                        texture2d<float> materialColour [[texture(TextureIndexAlbedo)]],
                                                        depth2d<float, access::read> depthTexture [[texture(1)]]) {
    
    
    float4 position = in.position;
    float4x4 projectionMatrix = uniforms.projectionMatrix;
    half p22 = half(projectionMatrix[2][2]);
    half p23 = half(projectionMatrix[3][2]);
    
    uint2 texPos = uint2(in.position.xy);
    half depth = half(depthTexture.read(texPos));
    
    half linearBackDepth  = p23 / (depth + p22);
    half linearFrontDepth = p23 / (half(position.z) + p22);
    half3 extinction = half3(0.056h, 0.153h, 0.408h);
    half4 transmittance = half4(exp((linearFrontDepth - linearBackDepth) / 0.07h * extinction), 1.0h);
    
    constexpr sampler sampler2d(min_filter::nearest,
                                mag_filter::nearest);
    
    float2 texCoord = in.texCoords;
    half4 sampled = half4(materialColour.sample(sampler2d, texCoord));
    
    
    TransparentFragmentOut out;
    out.surface = sampled;
    out.transmittance = transmittance;
    return out;
}

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

constant half toneMapExposure = 0.8h;

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

