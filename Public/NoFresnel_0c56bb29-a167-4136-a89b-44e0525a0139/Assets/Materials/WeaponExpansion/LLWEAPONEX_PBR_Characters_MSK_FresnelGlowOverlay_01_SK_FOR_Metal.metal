//[Vertex shader]


#define __HAVE_MATRIX_MULTIPLE_SCALAR_CONSTRUCTORS__
#include <metal_stdlib>

using namespace metal;

#include "Shaders/Metal/CommonHelpers.shdh"
#include "Shaders/GlobalConstants_MTL.shdh"
#include "Shaders/GlobalConstants_PS_MTL.shdh"

typedef struct
{
	uint4 BoneIndices BLENDINDICES0;
	float4 BoneWeights BLENDWEIGHT0;
	float3 Position SV_POSITION0;
	float4 LocalQTangent NORMAL0;
	float2 TexCoords0 TEXCOORD0;
} VertexInput;

typedef struct
{
	float4 ProjectedPosition [[position]];
	float3 WorldNormal;
	float3 WorldBinormal;
	float3 WorldTangent;
	float3 WorldView;
	float2 TexCoords0;
	float HeightFog;
	float DistanceFog;
} VertexOutput;

struct LocalUniformsVS
{
	float3x4 BoneMatrices[128];
	float4x4 WorldMatrix;
};

vertex VertexOutput WeaponExpansion_LLWEAPONEX_PBR_Characters_MSK_FresnelGlowOverlay_01_SK_FOR_Metal_vertexMain(constant LocalUniformsVS& uniforms [[buffer(5)]],
	constant PerView& perView [[buffer(6)]],
	constant PerFrame& perFrame [[buffer(7)]],
	VertexInput In [[stage_in]])
{
	VertexOutput Out;

	float4x3 boneMatrix1 = transpose(uniforms.BoneMatrices[In.BoneIndices.x]);
	float4x3 boneMatrix2 = transpose(uniforms.BoneMatrices[In.BoneIndices.y]);
	float4x3 boneMatrix3 = transpose(uniforms.BoneMatrices[In.BoneIndices.z]);
	float4x3 boneMatrix4 = transpose(uniforms.BoneMatrices[In.BoneIndices.w]);
	//World space position
	float4 worldPosition = float4(0.0f, 0.0f, 0.0f, 1.0f);
	worldPosition.xyz = (worldPosition.xyz + (In.BoneWeights.x * (boneMatrix1 * float4(In.Position, 1.0f))));
	worldPosition.xyz = (worldPosition.xyz + (In.BoneWeights.y * (boneMatrix2 * float4(In.Position, 1.0f))));
	worldPosition.xyz = (worldPosition.xyz + (In.BoneWeights.z * (boneMatrix3 * float4(In.Position, 1.0f))));
	worldPosition.xyz = (worldPosition.xyz + (In.BoneWeights.w * (boneMatrix4 * float4(In.Position, 1.0f))));
	worldPosition = (uniforms.WorldMatrix * worldPosition);

	//Projected position
	float4 projectedPosition = (perView.global_ViewProjection * worldPosition);

	//Pass projected position to pixel shader
	Out.ProjectedPosition = projectedPosition;

	//Compute local tangent frame
	float3x3 LocalTangentFrame = GetTangentFrame(In.LocalQTangent);

	float3 LocalNormal = LocalTangentFrame[2];

	//Normalize Local Normal
	float3 localNormalNormalized = normalize(LocalNormal);

	//World space Normal
	float3 worldNormal = float3(0.0f, 0.0f, 0.0f);
	worldNormal = (worldNormal + (In.BoneWeights.x * (boneMatrix1 * float4(localNormalNormalized, 0.0f))));
	worldNormal = (worldNormal + (In.BoneWeights.y * (boneMatrix2 * float4(localNormalNormalized, 0.0f))));
	worldNormal = (worldNormal + (In.BoneWeights.z * (boneMatrix3 * float4(localNormalNormalized, 0.0f))));
	worldNormal = (worldNormal + (In.BoneWeights.w * (boneMatrix4 * float4(localNormalNormalized, 0.0f))));
	worldNormal = (uniforms.WorldMatrix * float4(worldNormal, 0.0f)).xyz;

	//Normalize World Normal
	float3 worldNormalNormalized = normalize(worldNormal);

	Out.WorldNormal = worldNormalNormalized;

	float3 LocalBinormal = LocalTangentFrame[1];

	//Normalize Local Binormal
	float3 localBinormalNormalized = normalize(LocalBinormal);

	//World space Binormal
	float3 worldBinormal = float3(0.0f, 0.0f, 0.0f);
	worldBinormal = (worldBinormal + (In.BoneWeights.x * (boneMatrix1 * float4(localBinormalNormalized, 0.0f))));
	worldBinormal = (worldBinormal + (In.BoneWeights.y * (boneMatrix2 * float4(localBinormalNormalized, 0.0f))));
	worldBinormal = (worldBinormal + (In.BoneWeights.z * (boneMatrix3 * float4(localBinormalNormalized, 0.0f))));
	worldBinormal = (worldBinormal + (In.BoneWeights.w * (boneMatrix4 * float4(localBinormalNormalized, 0.0f))));
	worldBinormal = (uniforms.WorldMatrix * float4(worldBinormal, 0.0f)).xyz;

	//Normalize World Binormal
	float3 worldBinormalNormalized = normalize(worldBinormal);

	Out.WorldBinormal = worldBinormalNormalized;

	float3 LocalTangent = LocalTangentFrame[0];

	//Normalize Local Tangent
	float3 localTangentNormalized = normalize(LocalTangent);

	//World space Tangent
	float3 worldTangent = float3(0.0f, 0.0f, 0.0f);
	worldTangent = (worldTangent + (In.BoneWeights.x * (boneMatrix1 * float4(localTangentNormalized, 0.0f))));
	worldTangent = (worldTangent + (In.BoneWeights.y * (boneMatrix2 * float4(localTangentNormalized, 0.0f))));
	worldTangent = (worldTangent + (In.BoneWeights.z * (boneMatrix3 * float4(localTangentNormalized, 0.0f))));
	worldTangent = (worldTangent + (In.BoneWeights.w * (boneMatrix4 * float4(localTangentNormalized, 0.0f))));
	worldTangent = (uniforms.WorldMatrix * float4(worldTangent, 0.0f)).xyz;

	//Normalize World Tangent
	float3 worldTangentNormalized = normalize(worldTangent);

	Out.WorldTangent = worldTangentNormalized;

	//World space view vector
	float3 worldView = (perView.global_ViewPos.xyz - worldPosition.xyz);

	Out.WorldView = worldView;

	Out.TexCoords0 = In.TexCoords0;
	//Calculate Height Fog
	float depthValue = saturate(((perFrame.global_FogPropertyMatrix[3].y - length(worldView)) / (perFrame.global_FogPropertyMatrix[3].y - perFrame.global_FogPropertyMatrix[3].x)));
	float heightDensity = ((worldPosition.y - perFrame.global_FogPropertyMatrix[2].z) / perFrame.global_FogPropertyMatrix[3].z);
	float heightFog = saturate(max(depthValue, heightDensity));

	Out.HeightFog = heightFog;

	//Calculate Distance Fog
	float distanceFog = saturate(((perFrame.global_FogPropertyMatrix[2].y - length(worldView)) / (perFrame.global_FogPropertyMatrix[2].y - perFrame.global_FogPropertyMatrix[2].x)));

	Out.DistanceFog = distanceFog;


	return Out;
}


//[Fragment shader]


#include "Shaders/Metal/PBR.shdh"
#include "Shaders/Metal/Exposure.shdh"
#include "Shaders/Metal/ImageBasedLightingHelpers.shdh"

typedef struct
{
	float4 Color0 [[color(0)]];
} PixelOutput;

struct LocalUniformsPS
{
	float _OpacityFade;
	float FloatParameter_Speed;
	float FloatParameter_PulseMin;
	float FloatParameter_PulseMax;
	float4 Vector4Parameter_Color;
	float FloatParameter_RainbowFresnelStrength;
	float FloatParameter_AddedColorRepeat;
	float FloatParameter_RainbowColourStrength;
	float FloatParameter_Map01EmissiveMult;
	float2 Vector2Parameter_Map01Panner;
	float2 Vector2Parameter_Map01Tiling;
	float2 Vector2Parameter_UVNoisePanner;
	float2 Vector2Parameter_UVNoiseTiling;
	float FloatParameter_Map01UVNoiseMult;
	float FloatParameter_Map01Contrast;
	float3 Vector3Parameter_Map01ColorMult;
	float2 Vector2Parameter_Map02Panner;
	float2 Vector2Parameter_Map02Tiling;
	float FloatParameter_Map02UVNoiseMult;
	float FloatParameter_Map02Contrast;
	float3 Vector3Parameter_Map02ColorMult;
	float FloatParameter_Map02EmissiveMult;
	float FloatParameter_EmissivePower;
	float FloatParameter_FresnelPulseSpeed;
	float FloatParameter_FresnelPower;
	float FloatParameter_FresnelMax;
	float FloatParameter_InverseFresnel;
	float FloatParameter_Opacity;
	float4 Vector4Parameter_Color1;
	float4 Vector4Parameter_Color2;
	float4 Vector4Parameter_Color3;
	float4 Vector4Parameter_Color4;
	float4 Vector4Parameter_Color5;
	float FloatParameter_Reflectance;
	EXPOSURE_UNIFORMS
	IBL_UNIFORMS
};

static void CalculateMatEmissiveColor(constant LocalUniformsPS& uniforms,
	constant PerFrame& perFrame,
	float3 in_0,
	float2 in_1,
	thread float3& out_0,
	sampler _DefaultWrapSampler,
	texture2d<float> Texture2DParameter_9dc5807b36974b8fab0fb9c5c1bd7010_DefaultWrapSampler,
	texture2d<float> Texture2DParameter_WorldPositionColorMap_DefaultWrapSampler,
	texture2d<float> Texture2DParameter_UVNoiseMap_DefaultWrapSampler,
	texture2d<float> Texture2DParameter_EmissiveMap01_DefaultWrapSampler,
	texture2d<float> Texture2DParameter_EmissiveMap02_DefaultWrapSampler)
{
	float Local0 = (perFrame.global_Data.x * uniforms.FloatParameter_Speed);
	float Local1 = ((((sin(Local0) * 0.5f) + 0.5f) * (uniforms.FloatParameter_PulseMax - uniforms.FloatParameter_PulseMin)) + uniforms.FloatParameter_PulseMin);
	float3 Local2 = uniforms.Vector4Parameter_Color.xyz;
	float Local3 = pow((1.0f - saturate(dot(float3(0.0f, 1.0f, 0.0f), in_0))), uniforms.FloatParameter_RainbowFresnelStrength);
	float2 Local4 = (in_1 * uniforms.FloatParameter_AddedColorRepeat);
	float4 Local5 = Texture2DParameter_9dc5807b36974b8fab0fb9c5c1bd7010_DefaultWrapSampler.sample(_DefaultWrapSampler, (Local4 + (float2(0.05f, 0.03f) * perFrame.global_Data.x)));
	//[Local5] Get needed components
	float Local6 = Local5.x;
	float4 Local7 = Texture2DParameter_WorldPositionColorMap_DefaultWrapSampler.sample(_DefaultWrapSampler, float2(Local6, Local6));
	//[Local7] Get needed components
	float3 Local8 = Local7.xyz;
	float3 Local9 = (Local8 * uniforms.FloatParameter_RainbowColourStrength);
	float3 Local10 = (Local3 * Local9);
	float Local11 = (perFrame.global_Data.x * 0.1f);
	float2 Local12 = (in_1 * uniforms.Vector2Parameter_Map01Tiling);
	float2 Local13 = (in_1 * uniforms.Vector2Parameter_UVNoiseTiling);
	float2 Local14 = fma(uniforms.Vector2Parameter_UVNoisePanner, perFrame.global_Data.x, Local13);
	float4 Local15 = Texture2DParameter_UVNoiseMap_DefaultWrapSampler.sample(_DefaultWrapSampler, Local14);
	//[Local15] Get needed components
	float Local16 = Local15.x;
	float Local17 = fma(Local16, 2.0f, -1.0f);
	float Local18 = (uniforms.FloatParameter_Map01UVNoiseMult * 0.01f);
	float Local19 = (Local17 * Local18);
	float2 Local20 = (Local12 + Local19);
	float2 Local21 = fma(uniforms.Vector2Parameter_Map01Panner, Local11, Local20);
	float4 Local22 = Texture2DParameter_EmissiveMap01_DefaultWrapSampler.sample(_DefaultWrapSampler, Local21);
	//[Local22] Get needed components
	float Local23 = Local22.x;
	float Local24 = pow(Local23, uniforms.FloatParameter_Map01Contrast);
	float3 Local25 = (Local24 * uniforms.Vector3Parameter_Map01ColorMult);
	float3 Local26 = (uniforms.FloatParameter_Map01EmissiveMult * Local25);
	float Local27 = (perFrame.global_Data.x * 0.1f);
	float2 Local28 = (in_1 * uniforms.Vector2Parameter_Map02Tiling);
	float Local29 = (uniforms.FloatParameter_Map02UVNoiseMult * 0.01f);
	float Local30 = (Local17 * Local29);
	float2 Local31 = (Local28 + Local30);
	float2 Local32 = fma(uniforms.Vector2Parameter_Map02Panner, Local27, Local31);
	float4 Local33 = Texture2DParameter_EmissiveMap02_DefaultWrapSampler.sample(_DefaultWrapSampler, Local32);
	//[Local33] Get needed components
	float Local34 = Local33.x;
	float Local35 = pow(Local34, uniforms.FloatParameter_Map02Contrast);
	float3 Local36 = (Local35 * uniforms.Vector3Parameter_Map02ColorMult);
	float3 Local37 = (Local36 * uniforms.FloatParameter_Map02EmissiveMult);
	float3 Local38 = (Local26 + Local37);
	float3 Local39 = pow(Local38, uniforms.FloatParameter_EmissivePower);
	float3 Local40 = (Local10 + Local39);
	float3 Local41 = (Local2 * Local40);
	float Local42 = uniforms.Vector4Parameter_Color.w;
	float Local43 = (Local24 * Local35);
	float Local44 = (perFrame.global_Data.x * uniforms.FloatParameter_FresnelPulseSpeed);
	float Local45 = ((((sin(Local44) * 0.5f) + 0.5f) * (uniforms.FloatParameter_FresnelMax - uniforms.FloatParameter_FresnelPower)) + uniforms.FloatParameter_FresnelPower);
	float Local46 = pow((1.0f - saturate(dot(float3(0.0f, 1.0f, 0.0f), in_0))), Local45);
	float Local47 = (1.0f - Local46);
	float Local48 = mix(Local46, Local47, uniforms.FloatParameter_InverseFresnel);
	float Local49 = (Local43 * Local48);
	float Local50 = (Local49 * uniforms.FloatParameter_Opacity);
	float Local51 = (Local42 * Local50);
	float Local52 = clamp(Local51, 0.0f, 1.0f);
	float3 Local53 = (Local41 * Local52);
	float3 Local54 = (Local1 * Local53);
	out_0 = Local54;
}

static void CalculateMatNormal(float2 in_0,
	thread float3& out_0,
	sampler _DefaultWrapSampler,
	texture2d<float> Texture2DParameter_normalmap_DefaultWrapSampler)
{
	float4 Local0 = Texture2DParameter_normalmap_DefaultWrapSampler.sample(_DefaultWrapSampler, in_0);
	//[Local0] Convert normalmaps to tangent space vectors
	Local0.xyzw = Local0.wzyx;
	Local0.xyz = ((Local0.xyz * 2.0f) - 1.0f);
	Local0.z = -(Local0.z);
	Local0.xyz = normalize(Local0.xyz);
	//[Local0] Get needed components
	float3 Local1 = Local0.xyz;
	out_0 = Local1;
}

static void CalculateMatBaseColor(constant LocalUniformsPS& uniforms,
	float2 in_0,
	thread float3& out_0,
	sampler _DefaultWrapSampler,
	texture2d<float> Texture2DParameter_MSKskin_DefaultWrapSampler,
	texture2d<float> Texture2DParameter_MSKcloth_DefaultWrapSampler,
	texture2d<float> Texture2DParameter_basecolor_DefaultWrapSampler)
{
	float4 Local0 = Texture2DParameter_MSKskin_DefaultWrapSampler.sample(_DefaultWrapSampler, in_0);
	//[Local0] Get needed components
	float Local1 = Local0.x;
	float Local2 = Local0.y;
	float4 Local3 = (uniforms.Vector4Parameter_Color1 * Local1);
	float4 Local4 = (uniforms.Vector4Parameter_Color2 * Local2);
	float4 Local5 = (Local3 + Local4);
	float4 Local6 = Texture2DParameter_MSKcloth_DefaultWrapSampler.sample(_DefaultWrapSampler, in_0);
	//[Local6] Get needed components
	float Local7 = Local6.x;
	float Local8 = Local6.y;
	float Local9 = Local6.z;
	float4 Local10 = (uniforms.Vector4Parameter_Color3 * Local7);
	float4 Local11 = (Local5 + Local10);
	float4 Local12 = (uniforms.Vector4Parameter_Color4 * Local8);
	float4 Local13 = (Local11 + Local12);
	float4 Local14 = (uniforms.Vector4Parameter_Color5 * Local9);
	float4 Local15 = (Local13 + Local14);
	float Local16 = (1.0f - Local1);
	float Local17 = (1.0f - Local2);
	float Local18 = (Local16 * Local17);
	float Local19 = (1.0f - Local7);
	float Local20 = (Local18 * Local19);
	float Local21 = (1.0f - Local8);
	float Local22 = (Local20 * Local21);
	float Local23 = (1.0f - Local9);
	float Local24 = (Local22 * Local23);
	float Local25 = pow(Local24, 2.2f);
	float4 Local26 = (Local15 + Local25);
	float3 Local27 = Local26.xyz;
	float4 Local28 = Texture2DParameter_basecolor_DefaultWrapSampler.sample(_DefaultWrapSampler, in_0);
	//[Local28] Get needed components
	float3 Local29 = Local28.xyz;
	float3 Local30 = (Local27 * Local29);
	out_0 = Local30;
}

static void CalculateMatMetalMask(float2 in_0,
	thread float& out_0,
	sampler _DefaultWrapSampler,
	texture2d<float> Texture2DParameter_physicalmap_DefaultWrapSampler)
{
	float4 Local0 = Texture2DParameter_physicalmap_DefaultWrapSampler.sample(_DefaultWrapSampler, in_0);
	//[Local0] Get needed components
	float Local1 = Local0.x;
	float Local2 = Local0.y;
	out_0 = Local1;
}

static void CalculateMatReflectance(constant LocalUniformsPS& uniforms,
	thread float& out_0)
{
	out_0 = uniforms.FloatParameter_Reflectance;
}

static void CalculateMatRoughness(float2 in_0,
	thread float& out_0,
	sampler _DefaultWrapSampler,
	texture2d<float> Texture2DParameter_physicalmap_DefaultWrapSampler)
{
	float4 Local0 = Texture2DParameter_physicalmap_DefaultWrapSampler.sample(_DefaultWrapSampler, in_0);
	//[Local0] Get needed components
	float Local1 = Local0.x;
	float Local2 = Local0.y;
	out_0 = Local2;
}

fragment PixelOutput WeaponExpansion_LLWEAPONEX_PBR_Characters_MSK_FresnelGlowOverlay_01_SK_FOR_Metal_fragmentMain(constant LocalUniformsPS& uniforms,
	constant PerFrame& perFrame,
	VertexOutput In [[stage_in]],
	sampler _DefaultWrapSampler,
	texture2d<float> Texture2DParameter_9dc5807b36974b8fab0fb9c5c1bd7010_DefaultWrapSampler,
	texture2d<float> Texture2DParameter_WorldPositionColorMap_DefaultWrapSampler,
	texture2d<float> Texture2DParameter_UVNoiseMap_DefaultWrapSampler,
	texture2d<float> Texture2DParameter_EmissiveMap01_DefaultWrapSampler,
	texture2d<float> Texture2DParameter_EmissiveMap02_DefaultWrapSampler,
	texture2d<float> Texture2DParameter_normalmap_DefaultWrapSampler,
	texture2d<float> Texture2DParameter_MSKskin_DefaultWrapSampler,
	texture2d<float> Texture2DParameter_MSKcloth_DefaultWrapSampler,
	texture2d<float> Texture2DParameter_basecolor_DefaultWrapSampler,
	texture2d<float> Texture2DParameter_physicalmap_DefaultWrapSampler,
	EXPOSURE_PARAMS,
	IBL_PARAMS)
{
	PixelOutput Out;

	float3 matEmissiveColor;
	//Normalize World Normal
	float3 worldNormalNormalized = normalize(In.WorldNormal);

	//Normalize World Binormal
	float3 worldBinormalNormalized = normalize(In.WorldBinormal);

	//Normalize World Tangent
	float3 worldTangentNormalized = normalize(In.WorldTangent);

	float3x3 NBT = float3x3(float3(worldTangentNormalized.x, worldNormalNormalized.x, worldBinormalNormalized.x), float3(worldTangentNormalized.y, worldNormalNormalized.y, worldBinormalNormalized.y), float3(worldTangentNormalized.z, worldNormalNormalized.z, worldBinormalNormalized.z));

	//Normalized world space view vector
	float3 worldViewNormalized = normalize(In.WorldView);

	//Calculate tangent space view vector
	float3 tangentView = (NBT * worldViewNormalized);

	CalculateMatEmissiveColor(uniforms, perFrame, tangentView, In.TexCoords0, matEmissiveColor, _DefaultWrapSampler, Texture2DParameter_9dc5807b36974b8fab0fb9c5c1bd7010_DefaultWrapSampler, Texture2DParameter_WorldPositionColorMap_DefaultWrapSampler, Texture2DParameter_UVNoiseMap_DefaultWrapSampler, Texture2DParameter_EmissiveMap01_DefaultWrapSampler, Texture2DParameter_EmissiveMap02_DefaultWrapSampler);
	float3 matNormal;
	CalculateMatNormal(In.TexCoords0, matNormal, _DefaultWrapSampler, Texture2DParameter_normalmap_DefaultWrapSampler);
	matNormal = normalize((matNormal * NBT));

	float3 matBaseColor;
	CalculateMatBaseColor(uniforms, In.TexCoords0, matBaseColor, _DefaultWrapSampler, Texture2DParameter_MSKskin_DefaultWrapSampler, Texture2DParameter_MSKcloth_DefaultWrapSampler, Texture2DParameter_basecolor_DefaultWrapSampler);
	float matMetalMask;
	CalculateMatMetalMask(In.TexCoords0, matMetalMask, _DefaultWrapSampler, Texture2DParameter_physicalmap_DefaultWrapSampler);
	float matReflectance;
	CalculateMatReflectance(uniforms, matReflectance);
	matReflectance = RemapReflectance(matReflectance);
	float matRoughness;
	CalculateMatRoughness(In.TexCoords0, matRoughness, _DefaultWrapSampler, Texture2DParameter_physicalmap_DefaultWrapSampler);
	matRoughness = max(0.09f, matRoughness);
	float3 FinalColor = float3(0.0f, 0.0f, 0.0f);

	//Calculate Image Based Lighting
	float3 iblDiffuse;
	float3 iblSpecular;
	EvaluateDistantIBL(matBaseColor, matRoughness, float3(matReflectance, matReflectance, matReflectance), matMetalMask, matNormal, worldViewNormalized, iblDiffuse, iblSpecular, IBL_PARAMS_CONSTRUCT);
	FinalColor = ((FinalColor + iblDiffuse) + iblSpecular);

	float3 LightDiffuseColorOut;
	float3 LightSpecularColorOut;
	DirectionLight(matNormal, worldViewNormalized, perFrame.global_LightPropertyMatrix, matBaseColor, matReflectance, matRoughness, matMetalMask, LightDiffuseColorOut, LightSpecularColorOut);
	FinalColor = ((FinalColor + LightDiffuseColorOut) + LightSpecularColorOut);

	FinalColor = PreExpose(FinalColor, Exposure);

	FinalColor = (FinalColor + (matEmissiveColor * !(bool)(perFrame.global_Data.y)));

	FinalColor = mix(perFrame.global_FogPropertyMatrix[1].xyz, FinalColor, float3(In.HeightFog, In.HeightFog, In.HeightFog));
	FinalColor = mix(perFrame.global_FogPropertyMatrix[0].xyz, FinalColor, float3(In.DistanceFog, In.DistanceFog, In.DistanceFog));

	Out.Color0 = float4(FinalColor, uniforms._OpacityFade);
	Out.Color0 = max(Out.Color0, 0.0f);

	return Out;
}
