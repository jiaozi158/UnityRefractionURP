#ifndef URP_REFRACTION_HLSL
#define URP_REFRACTION_HLSL

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Refraction.hlsl"

void RefractionModelSphere_float(half3 viewDir, float3 position, half3 normal, half ior, half Thickness, out half rayDistance, out float3 rayPositionWS, out half3 rayDirWS)
{
    RefractionModelResult refractedRay = RefractionModelSphere(viewDir, position, normal, ior, Thickness);

    rayDistance = refractedRay.dist;
    rayPositionWS = refractedRay.positionWS;
    rayDirWS = refractedRay.rayWS;
}

void RefractionModelBox_float(half3 viewDir, float3 position, half3 normal, half ior, half Thickness, out half rayDistance, out float3 rayPositionWS, out half3 rayDirWS)
{
    RefractionModelResult refractedRay = RefractionModelBox(viewDir, position, normal, ior, Thickness);

    rayDistance = refractedRay.dist;
    rayPositionWS = refractedRay.positionWS;
    rayDirWS = refractedRay.rayWS;
}

void IsInScreenSpace_float(float2 refractUV, out bool isInScreenSpace)
{
    if (refractUV.x > 0.0 && refractUV.y > 0.0 && refractUV.x < 1.0 && refractUV.y < 1.0)
    {
        isInScreenSpace = true;
    }
    else
    {
        isInScreenSpace = false;
    }
}

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UnityInput.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/GeometricTools.hlsl"

half3 BoxProjectedDirection(half3 reflectVector, float3 positionWS, float3 probePosition, half3 boxMin, half3 boxMax)
{
    float3 factors = ((reflectVector > 0 ? boxMax : boxMin) - positionWS) * rcp(reflectVector);
    float scalar = min(min(factors.x, factors.y), factors.z);
    half3 sampleVector = reflectVector * scalar + (positionWS - probePosition);
    return sampleVector;
}

// Forward+ Reflection Probe Atlas
#if USE_FORWARD_PLUS

// The name of ZBinBuffer is different between 2022.x and 2023.x
#if UNITY_VERSION >= 202310
#define URP_ZBins urp_ZBins
#else
#define urp_ZBins URP_ZBins
#endif

// used by Forward+
uint FindMainProbeInAtlas(half3 reflectVector, float3 positionWS, float2 normalizedScreenSpaceUV)
{
    float totalWeight = 0.0f;
    float highestWeight = 0.0f; // Main Probe Weight
    uint mainIndex = 0;         // Main Probe Index
    uint probeIndex;
    ClusterIterator it = ClusterInit(normalizedScreenSpaceUV, positionWS, 1);
    [loop] while (ClusterNext(it, probeIndex) && totalWeight < 0.99f && probeIndex <= 32 && highestWeight < 0.5f) // Exit if we find the main probe
    {
        probeIndex -= URP_FP_PROBES_BEGIN;

        float weight = CalculateProbeWeight(positionWS, urp_ReflProbes_BoxMin[probeIndex], urp_ReflProbes_BoxMax[probeIndex]);
        weight = min(weight, 1.0f - totalWeight);

        bool isHigher = weight > highestWeight;
        highestWeight = isHigher ? weight : highestWeight;
        mainIndex = isHigher ? probeIndex : mainIndex;
    }
    return mainIndex;
}

#endif // USE_FORWARD_PLUS

void ScreenSpaceReflProbeRaycastRefraction_float(float3 rayPositionWS, half3 rayDirWS, float2 screenUV, out bool hitSuccessful, out float2 hitPositionNDC, out float3 hitPositionWS, out float4 hitPositionCS, out half3 probeColor)
{
    // For Forward+ path, we use main probe (the one with highest weight) to project refraction direction.
#if USE_FORWARD_PLUS
    uint probeIndex = FindMainProbeInAtlas(hitPositionWS, rayPositionWS, screenUV);

    // Reflection Probe position as the origin. (Not the capture position)
    float3 positionPS = rayPositionWS - urp_ReflProbes_ProbePosition[probeIndex].xyz;
    float3 dirPS = rayPositionWS;

    float projectionDistance = -1.0;
    // Check if the probe is box projected.
    // Catlike Coding's "Optional Projection" at https://catlikecoding.com/unity/tutorials/rendering/part-8/
    UNITY_BRANCH
    if (urp_ReflProbes_ProbePosition[probeIndex].w > 0) // Box Projection Shape
    {
        projectionDistance = IntersectRayAABBSimple(positionPS, dirPS, urp_ReflProbes_BoxMin[probeIndex].xyz, urp_ReflProbes_BoxMax[probeIndex].xyz);
    }
    else // Infinite or Sphere Projection Shape
    {
        const float sphereOuterDistance = 32752; // Radius of sphere probe. // proxyExtents.x = 0.5f * Vector3.Max(-boxSizes[p], boxSizes[p]);
        projectionDistance = IntersectRaySphereSimple(positionPS, dirPS, sphereOuterDistance);
        projectionDistance = IsNaN(projectionDistance) ? -1.0f : projectionDistance; // Note that because we use IntersectRaySphereSimple, in case of a ill-set proxy, it could be that
                                                                                    // the determinant in the ray-sphere intersection code ends up negative, leading to a NaN.
                                                                                    // Rather than complicating the IntersectRaySphereSimple or switching to a more complex case, we cover that case this way.

        const float minProjectionDistance = 65504; // No Sphere Shape in current URP.
        projectionDistance = max(projectionDistance, minProjectionDistance); // Setup projection to infinite if requested (mean no projection shape)
    }

    hitPositionWS = rayPositionWS + rayDirWS * projectionDistance;
    hitPositionCS = ComputeClipSpacePosition(hitPositionWS, GetWorldToHClipMatrix());
    float4 rayPositionCS = ComputeClipSpacePosition(rayPositionWS, GetWorldToHClipMatrix());
    hitPositionNDC = ComputeNormalizedDeviceCoordinates(hitPositionWS, GetWorldToHClipMatrix());

    hitSuccessful = hitPositionCS.w > 0;    // Negative means that the hit is behind the camera

    probeColor = half3(0.0, 0.0, 0.0);
    #if defined(_RAYMISS_FALLBACK_REFLECTION_PROBES)
    // Box Projection
    half3 sampleVector = hitPositionWS;
    sampleVector = BoxProjectedDirection(hitPositionWS, rayPositionWS, urp_ReflProbes_ProbePosition[probeIndex].xyz, urp_ReflProbes_BoxMin[probeIndex].xyz, urp_ReflProbes_BoxMax[probeIndex].xyz);

    // Reflection Probe Mipmaps
    uint maxMip = (uint)abs(urp_ReflProbes_ProbePosition[probeIndex].w) - 1;
    half probeMip = min(0, maxMip);
    float2 uv = saturate(PackNormalOctQuadEncode(sampleVector) * 0.5 + 0.5);

    float mip0 = floor(probeMip);
    float4 scaleOffset0 = urp_ReflProbes_MipScaleOffset[probeIndex * 7 + (uint)mip0];

    probeColor = SAMPLE_TEXTURE2D_LOD(urp_ReflProbes_Atlas, samplerurp_ReflProbes_Atlas, uv * scaleOffset0.xy + scaleOffset0.zw, 0).rgb;
    #endif
#else
    // Current URP does not support Reflection Probe rotation.
    // This feature should be available in the future.
    /*
    float3 proxyRight = float3(1, 0, 0);   // X-axis rotation, Column(0) of probeToWorld TRS matrix.

    float3 proxyUp = float3(0, 1, 0);      // Y-axis rotation, Column(1) of probeToWorld TRS matrix.

    float3 proxyForward = float3(0, 0, 1); // Z-axis rotation, Column(2) of probeToWorld TRS matrix.

    float3x3 worldToReflProbe = transpose(
            float3x3(
            proxyRight,
            proxyUp,
            proxyForward
            )
    ); // worldToLocal assume no scaling

    float3 dirPS = mul(rayPositionWS, worldToReflProbe).xyz;

    // Reflection Probe position as the origin. (Not the capture position)
    float3 positionPS = rayPositionWS - unity_SpecCube0_ProbePosition.xyz;
    positionPS = mul(positionPS, worldToReflProbe).xyz;
    */

    // Reflection Probe position as the origin. (Not the capture position)
    float3 positionPS = rayPositionWS - unity_SpecCube0_ProbePosition.xyz;
    float3 dirPS = rayPositionWS;

    float projectionDistance = -1.0;
    // Check if the probe is box projected.
    // Catlike Coding's "Optional Projection" at https://catlikecoding.com/unity/tutorials/rendering/part-8/
    UNITY_BRANCH
    if (unity_SpecCube0_ProbePosition.w > 0) // Box Projection Shape
    {
        projectionDistance = IntersectRayAABBSimple(positionPS, dirPS, unity_SpecCube0_BoxMin.xyz, unity_SpecCube0_BoxMax.xyz);
    }
    else // Infinite or Sphere Projection Shape
    {
        const float sphereOuterDistance = 32752; // Radius of sphere probe. // proxyExtents.x = 0.5f * Vector3.Max(-boxSizes[p], boxSizes[p]);
        projectionDistance = IntersectRaySphereSimple(positionPS, dirPS, sphereOuterDistance);
        projectionDistance = IsNaN(projectionDistance) ? -1.0f : projectionDistance; // Note that because we use IntersectRaySphereSimple, in case of a ill-set proxy, it could be that
                                                                                    // the determinant in the ray-sphere intersection code ends up negative, leading to a NaN.
                                                                                    // Rather than complicating the IntersectRaySphereSimple or switching to a more complex case, we cover that case this way.

        const float minProjectionDistance = 65504; // No Sphere Shape in current URP.
        projectionDistance = max(projectionDistance, minProjectionDistance); // Setup projection to infinite if requested (mean no projection shape)
    }

    hitPositionWS = rayPositionWS + rayDirWS * projectionDistance;
    hitPositionCS = ComputeClipSpacePosition(hitPositionWS, GetWorldToHClipMatrix());
    float4 rayPositionCS = ComputeClipSpacePosition(rayPositionWS, GetWorldToHClipMatrix());
    hitPositionNDC = ComputeNormalizedDeviceCoordinates(hitPositionWS, GetWorldToHClipMatrix());

    hitSuccessful = hitPositionCS.w > 0;    // Negative means that the hit is behind the camera

    probeColor = half3(0.0, 0.0, 0.0);

    #if defined(_RAYMISS_FALLBACK_REFLECTION_PROBES)
    half4 sampleRefl = half4(0.0, 0.0, 0.0, 0.0);
    UNITY_BRANCH
    if (unity_SpecCube0_ProbePosition.w > 0) // Box Projection Probe
    {
        float3 uvw = BoxProjectedDirection(hitPositionWS, rayPositionWS, unity_SpecCube0_ProbePosition.xyz, unity_SpecCube0_BoxMin.xyz, unity_SpecCube0_BoxMax.xyz);
        sampleRefl = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, uvw, 0);
    }
    else // Infinite Projection Probe
    {
        sampleRefl = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, SafeNormalize(hitPositionWS), 0);
    }
    probeColor = DecodeHDREnvironment(sampleRefl, unity_SpecCube0_HDR);
    #endif
#endif // (USE_FORWARD_PLUS)
}

// Performs fading at the edge of the screen. 
void EdgeOfScreenFade_float(float2 screenUV, half fadeRcpLength, out half fadeFactor)
{
    float2 coordCS = screenUV * 2 - 1;
    float2 t = Remap10(abs(coordCS.xy), fadeRcpLength, fadeRcpLength);
    fadeFactor = Smoothstep01(t.x) * Smoothstep01(t.y);
}

// Transparent dithered shadow.
void IsMainLightShadow_half(out bool isMainLightShadow)
{
#if !defined (_CASTING_PUNCTUAL_LIGHT_SHADOW)
    isMainLightShadow = true;
#else
    isMainLightShadow = false;
#endif
}

// In case we set graph precision to single.
void IsMainLightShadow_float(out bool isMainLightShadow)
{
    IsMainLightShadow_half(isMainLightShadow);
}

#endif