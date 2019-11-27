//
//  PBRFunctions.metal
//  MetalPBR Shared
//
//  Created by Adil Patel on 14/09/2018.
//  Copyright © 2018 Adil Patel. All rights reserved.
//

// File for Metal kernel and shader functions

#include <metal_stdlib>

#import "ShaderSupport.metal"


using namespace metal;

// Light and material data
constant half3 directionalLightInvDirection = half3(0.0h, 1.0h, 0.0h);;

#define SRGB_ALPHA 0.055h

half linear_from_srgb(half x) {
    return (x <= 0.04045h) ? x / 12.92h : powr((x + SRGB_ALPHA) / (1.0h + SRGB_ALPHA), 2.4h);
}

half3 linear_from_srgb(half3 rgb) {
    return half3(linear_from_srgb(rgb.r), linear_from_srgb(rgb.g), linear_from_srgb(rgb.b));
}

vertex VertexOut helloVertexShader(Vertex in [[stage_in]],
                                   constant ObjectTransforms &uniforms [[buffer(BufferIndexLocalUniforms)]],
                                   constant PerFrameConstants &frameConstants [[buffer(BufferIndexPerFrameConstants)]]) {
    
    
    half3 position = half3(in.position);
    
    half4 transformedPos = half4(position, 1.0h);
    transformedPos = half4x4(uniforms.modelViewMatrix) * transformedPos;
    
    half4 projected = half4x4(frameConstants.projectionMatrix) * transformedPos;
    
    half3 normal = half3(in.normal);
    half3 tangent = half3(in.tangent);
    half3x3 normalMatrix = half3x3(uniforms.normalMatrix);
    
    VertexOut out;
    out.position = float4(projected); // Conversions from halfs to floats are free! :D
    out.texCoords = in.texCoords;
    out.worldPos = half3(transformedPos);
    out.normal = normalMatrix * normal;
    out.bitangent = normalMatrix * cross(normal, tangent);
    out.tangent = normalMatrix * tangent;
    
    return out;
}

// ----- PBR functions -----

static half3 diffuseTerm(LightingParameters parameters) {
    half3 diffusecolour = (parameters.basecolour.rgb / M_PI_H) * (1.0h - parameters.metalness);
    return diffusecolour * parameters.NdotL * parameters.diffuseLightcolour;
}

static half SchlickFresnel(half dotProduct) {
    return pow(clamp(1.0h - dotProduct, 0.0h, 1.0h), 5.0h);
}

static half Geometry(half NdotV, half alphaG) {
    half a = alphaG * alphaG;
    half b = NdotV * NdotV;
    return 1.0h / (NdotV + sqrt(a + b - a * b));
}


static half TRNDF(half NdotH, half roughness) {
    
    half roughnessSqr = roughness * roughness;
    
    half d = (NdotH * roughnessSqr - NdotH) * NdotH + 1.0h;
    return roughnessSqr / (M_PI_H * d * d);
}

static half TrowbridgeReitzNDF(half NdotH, half roughness) {
    return (roughness >= 1.0h) ? 1.0h / M_PI_H : TRNDF(NdotH, roughness);
}

static half3 specularTerm(LightingParameters parameters) {
    half specularRoughness = parameters.roughness * (1.0h - parameters.metalness) + parameters.metalness;
    
    half D = TrowbridgeReitzNDF(parameters.NdotH, specularRoughness);
    
    half Cspec0 = 0.04h;
    half3 F = mix(Cspec0, 1.0h, SchlickFresnel(parameters.HdotL));
    half alphaG = powr(specularRoughness * 0.5h + 0.5h, 2.0h);
    half G = Geometry(parameters.NdotL, alphaG) * Geometry(parameters.NdotV, alphaG);
    
    half3 specularOutput = (D * G * F * parameters.irradiatedcolour) * (1.0h + parameters.metalness * parameters.basecolour) +
    parameters.irradiatedcolour * parameters.metalness * parameters.basecolour;
    
    return specularOutput;
}

fragment half4 helloFragmentShader(VertexOut in                         [[stage_in]],
                                   constant PerFrameConstants &uniforms [[buffer(BufferIndexPerFrameConstants)]],
                                   texture2d<float> albedoMap           [[texture(TextureIndexAlbedo)]],
                                   texture2d<float> ambientOcclusionMap [[texture(TextureIndexAO)]],
                                   texture2d<float> emissiveMap         [[texture(TextureIndexEmissive)]],
                                   texture2d<float> metallicMap         [[texture(TextureIndexMetallic)]],
                                   texture2d<float> normalMap           [[texture(TextureIndexNormal)]],
                                   texture2d<float> roughnessMap        [[texture(TextureIndexRoughness)]],
                                   texturecube<float> irradianceMap     [[texture(TextureIndexIrradiance)]]) {
    
    constexpr sampler linearSampler (mip_filter::linear, mag_filter::linear, min_filter::linear);
    constexpr sampler mipSampler(min_filter::linear, mag_filter::linear, mip_filter::linear);
    constexpr sampler normalSampler(filter::nearest);
    
    const half3 diffuseLightcolour(4.0h);
    
    LightingParameters parameters;
    
    half4 basecolour = half4(albedoMap.sample(linearSampler, in.texCoords));
    parameters.basecolour = linear_from_srgb(basecolour.rgb);
    parameters.roughness = roughnessMap.sample(linearSampler, in.texCoords).g;
    parameters.metalness = metallicMap.sample(linearSampler, in.texCoords).b;
    half ambientOcclusion = ambientOcclusionMap.sample(linearSampler, in.texCoords).r;
    half3 mapNormal = half4(normalMap.sample(normalSampler, in.texCoords)).rgb * 2.0h - 1.0h;
    //mapNormal.y = -mapNormal.y; // Flip normal map Y-axis if necessary
    half3x3 TBN(in.tangent, in.bitangent, in.normal);
    parameters.normal = normalize(TBN * mapNormal);
    
    parameters.diffuseLightcolour = diffuseLightcolour;
    parameters.lightDir = directionalLightInvDirection;
    parameters.viewDir = normalize(half3(uniforms.cameraPosition) - in.worldPos);
    parameters.halfVector = normalize(parameters.lightDir + parameters.viewDir);
    parameters.reflectedVector = reflect(-parameters.viewDir, parameters.normal);
    
    parameters.NdotL = saturate(dot(parameters.normal, parameters.lightDir));
    parameters.NdotH = saturate(dot(parameters.normal, parameters.halfVector));
    parameters.NdotV = saturate(dot(parameters.normal, parameters.viewDir));
    parameters.HdotL = saturate(dot(parameters.lightDir, parameters.halfVector));
    
    float mipLevel = float(parameters.roughness * irradianceMap.get_num_mip_levels());
    parameters.irradiatedcolour = half3(irradianceMap.sample(mipSampler, float3(parameters.reflectedVector), level(mipLevel)).rgb) * ambientOcclusion;
    
    half3 emissivecolour = half3(emissiveMap.sample(linearSampler, in.texCoords).rgb);
    
    half3 colour = diffuseTerm(parameters) + specularTerm(parameters) + emissivecolour;
    
    return half4(colour, basecolour.a);
    
}