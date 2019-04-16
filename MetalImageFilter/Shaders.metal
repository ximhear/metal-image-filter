#include <metal_stdlib>
#include <metal_common>
#include <simd/simd.h>

using namespace metal;

constant float PI = 3.14159;
struct AdjustSaturationUniforms
{
    float saturationFactor;
};

kernel void adjust_saturation(texture2d<float, access::read> inTexture [[texture(0)]],
                              texture2d<float, access::write> outTexture [[texture(1)]],
                              constant AdjustSaturationUniforms &uniforms [[buffer(0)]],
                              uint2 gid [[thread_position_in_grid]])
{
    float4 inColor = inTexture.read(gid);
    float value = dot(inColor.rgb, float3(0.299, 0.587, 0.114));
    float4 grayColor(value, value, value, 1.0);
    float4 outColor = mix(grayColor, inColor, uniforms.saturationFactor);
    outTexture.write(outColor, gid);
}

kernel void gaussian_blur_2d(texture2d<float, access::read> inTexture [[texture(0)]],
                             texture2d<float, access::write> outTexture [[texture(1)]],
                             texture2d<float, access::read> weights [[texture(2)]],
                             uint2 gid [[thread_position_in_grid]])
{
    int size = weights.get_width();
    int radius = size / 2;
    
    float4 accumColor(0, 0, 0, 0);
    for (int j = 0; j < size; ++j)
    {
        for (int i = 0; i < size; ++i)
        {
            uint2 kernelIndex(i, j);
            uint2 textureIndex(gid.x + (i - radius), gid.y + (j - radius));
            float4 color = inTexture.read(textureIndex).rgba;
            float4 weight = weights.read(kernelIndex).rrrr;
            accumColor += weight * color;
        }
    }
    
    outTexture.write(float4(accumColor.rgb, 1), gid);
}

struct RotationUniforms
{
    float width;
    float height;
    float factor;
};

kernel void rotation_around_center(texture2d<float, access::read> inTexture [[texture(0)]],
                                   texture2d<float, access::write> outTexture [[texture(1)]],
                                   constant RotationUniforms &uniforms [[buffer(0)]],
                                   uint2 gid [[thread_position_in_grid]])
{
    float centerX = uniforms.width/2.0;
    float centerY = uniforms.height/2.0;
    float factor = uniforms.factor;

    float modX = (gid.x - centerX);
    float modY = (centerY - gid.y);
    float distance = sqrt(modX*modX + modY*modY);
    if (distance <= centerX) {
        float theta = factor * PI * pow(distance/centerX, 3);
        uint2 textureIndex(cos(theta) * modX - sin(theta) * modY + centerX, centerY - (sin(theta) * modX + cos(theta) * modY));
        float4 color = inTexture.read(textureIndex).rgba;
        outTexture.write(float4(color.rgb, 1), gid);
    }
    else {
        float4 color = inTexture.read(gid).rgba;
        outTexture.write(float4(color.rgb, 1), gid);
    }
}

struct RGBUniforms {
    float4x4 rotation;
};

kernel void gbr(texture2d<float, access::read> inTexture [[texture(0)]],
                texture2d<float, access::write> outTexture [[texture(1)]],
                constant RGBUniforms &uniforms [[buffer(0)]],
                uint2 gid [[thread_position_in_grid]])
{
    float4 inColor = inTexture.read(gid);
    float4 outColor =  uniforms.rotation * float4(inColor.rgb, 1);
    outTexture.write(outColor, gid);
}

kernel void sepia(texture2d<float, access::read> inTexture [[texture(0)]],
                texture2d<float, access::write> outTexture [[texture(1)]],
                uint2 gid [[thread_position_in_grid]])
{
    float4 inColor = inTexture.read(gid);
    
    float r = dot(inColor.rgb, float3(0.393, 0.769, 0.189));
    float g = dot(inColor.rgb, float3(0.349, 0.686, 0.168));
    float b = dot(inColor.rgb, float3(0.272, 0.534, 0.131));
    float4 outColor(r > 1 ? 1 : r, g > 1 ? 1 : g, b > 1 ? 1 : b, 1.0);
    outTexture.write(outColor, gid);
}

struct PixellationUniforms {
    int32_t width;
    int32_t height;
};

kernel void pixellate(texture2d<float, access::read> inTexture [[texture(0)]],
                texture2d<float, access::write> outTexture [[texture(1)]],
                constant PixellationUniforms &uniforms [[buffer(0)]],
                uint2 gid [[thread_position_in_grid]])
{
    uint width = uint(uniforms.width);
    uint height = uint(uniforms.height);
    
    const uint2 pixelGid = uint2((gid.x / width) * width, (gid.y / height) * height);
    float4 color = inTexture.read(pixelGid);
    outTexture.write(color, gid);
}

