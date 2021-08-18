//[Vertex shader]


#define __HAVE_MATRIX_MULTIPLE_SCALAR_CONSTRUCTORS__
#include <metal_stdlib>

using namespace metal;

#include "Shaders/Metal/CommonHelpers.shdh"
#include "Shaders/GlobalConstants_MTL.shdh"
#include "Shaders/GlobalConstants_PS_MTL.shdh"

typedef struct
{
	float3 Position SV_POSITION0;
	float2 TexCoords0 TEXCOORD0;
	float4 LocalQTangent NORMAL0;
} VertexInput;

typedef struct
{
	float4 ProjectedPosition [[position]];
	float2 TexCoords0;
	float3 WorldNormal;
	float3 WorldBinormal;
	float3 WorldTangent;
	float3 WorldView;
	float HeightFog;
	float DistanceFog;
} VertexOutput;

struct LocalUniformsVS
{
	float4x4 WorldMatrix;
};

vertex VertexOutput Characters_PBR_Characters_PBR_Anisotropic_AlphaTest_ST_FOR_Metal_vertexMain(constant LocalUniformsVS& uniforms [[buffer(5)]],
	constant PerView& perView [[buffer(6)]],
	constant PerFrame& perFrame [[buffer(7)]],
	VertexInput In [[stage_in]])
{
	VertexOutput Out;

	//World space position
	float4 worldPosition = (uniforms.WorldMatrix * float4(In.Position, 1.0f));

	//Projected position
	float4 projectedPosition = (perView.global_ViewProjection * worldPosition);

	//Pass projected position to pixel shader
	Out.ProjectedPosition = projectedPosition;

	Out.TexCoords0 = In.TexCoords0;
	//Compute local tangent frame
	float3x3 LocalTangentFrame = GetTangentFrame(In.LocalQTangent);

	float3 LocalNormal = LocalTangentFrame[2];

	//Normalize Local Normal
	float3 localNormalNormalized = normalize(LocalNormal);

	//World space Normal
	float3 worldNormal = (float3x3(uniforms.WorldMatrix[0].xyz, uniforms.WorldMatrix[1].xyz, uniforms.WorldMatrix[2].xyz) * localNormalNormalized);

	//Normalize World Normal
	float3 worldNormalNormalized = normalize(worldNormal);

	Out.WorldNormal = worldNormalNormalized;

	float3 LocalBinormal = LocalTangentFrame[1];

	//Normalize Local Binormal
	float3 localBinormalNormalized = normalize(LocalBinormal);

	//World space Binormal
	float3 worldBinormal = (float3x3(uniforms.WorldMatrix[0].xyz, uniforms.WorldMatrix[1].xyz, uniforms.WorldMatrix[2].xyz) * localBinormalNormalized);

	//Normalize World Binormal
	float3 worldBinormalNormalized = normalize(worldBinormal);

	Out.WorldBinormal = worldBinormalNormalized;

	float3 LocalTangent = LocalTangentFrame[0];

	//Normalize Local Tangent
	float3 localTangentNormalized = normalize(LocalTangent);

	//World space Tangent
	float3 worldTangent = (float3x3(uniforms.WorldMatrix[0].xyz, uniforms.WorldMatrix[1].xyz, uniforms.WorldMatrix[2].xyz) * localTangentNormalized);

	//Normalize World Tangent
	float3 worldTangentNormalized = normalize(worldTangent);

	Out.WorldTangent = worldTangentNormalized;

	//World space view vector
	float3 worldView = (perView.global_ViewPos.xyz - worldPosition.xyz);

	Out.WorldView = worldView;

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
	float4 Vector4Parameter_Color1;
	float4 Vector4Parameter_Color2;
	float4 Vector4Parameter_Color3;
	float4 Vector4Parameter_Color4;
	float4 Vector4Parameter_Color5;
	float FloatParameter_Reflectance;
	EXPOSURE_UNIFORMS
	IBL_UNIFORMS
};

static void CalculateMatOpacity(float2 in_0,
	thread float& out_0,
	sampler _DefaultWrapSampler,
	texture2d<float> Texture2DParameter_basecolor_DefaultWrapSampler)
{
	float4 Local0 = Texture2DParameter_basecolor_DefaultWrapSampler.sample(_DefaultWrapSampler, in_0);
	//[Local0] Get needed components
	float3 Local1 = Local0.xyz;
	float Local2 = Local0.w;
	out_0 = Local2;
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
	texture2d<float> Texture2DParameter_basecolor_DefaultWrapSampler,
	texture2d<float> Texture2DParameter_MSKskin_DefaultWrapSampler,
	texture2d<float> Texture2DParameter_MSKcloth_DefaultWrapSampler)
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
	float Local30 = Local28.w;
	float3 Local31 = (Local27 * Local29);
	out_0 = Local31;
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

static void CalculateMatAnisotropy(thread float& out_0)
{
	out_0 = 0.9f;
}

fragment PixelOutput Characters_PBR_Characters_PBR_Anisotropic_AlphaTest_ST_FOR_Metal_fragmentMain(constant LocalUniformsPS& uniforms,
	constant PerFrame& perFrame,
	VertexOutput In [[stage_in]],
	sampler _DefaultWrapSampler,
	texture2d<float> Texture2DParameter_basecolor_DefaultWrapSampler,
	texture2d<float> Texture2DParameter_normalmap_DefaultWrapSampler,
	texture2d<float> Texture2DParameter_MSKskin_DefaultWrapSampler,
	texture2d<float> Texture2DParameter_MSKcloth_DefaultWrapSampler,
	texture2d<float> Texture2DParameter_physicalmap_DefaultWrapSampler,
	EXPOSURE_PARAMS,
	IBL_PARAMS)
{
	PixelOutput Out;

	float matOpacity;
	CalculateMatOpacity(In.TexCoords0, matOpacity, _DefaultWrapSampler, Texture2DParameter_basecolor_DefaultWrapSampler);
	matOpacity = (matOpacity * uniforms._OpacityFade);

	if ((matOpacity - (0.5f * uniforms._OpacityFade)) < 0) discard_fragment();

	float3 matNormal;
	CalculateMatNormal(In.TexCoords0, matNormal, _DefaultWrapSampler, Texture2DParameter_normalmap_DefaultWrapSampler);
	//Normalize World Normal
	float3 worldNormalNormalized = normalize(In.WorldNormal);

	//Normalize World Binormal
	float3 worldBinormalNormalized = normalize(In.WorldBinormal);

	//Normalize World Tangent
	float3 worldTangentNormalized = normalize(In.WorldTangent);

	float3x3 NBT = float3x3(float3(worldTangentNormalized.x, worldNormalNormalized.x, worldBinormalNormalized.x), float3(worldTangentNormalized.y, worldNormalNormalized.y, worldBinormalNormalized.y), float3(worldTangentNormalized.z, worldNormalNormalized.z, worldBinormalNormalized.z));

	matNormal = normalize((matNormal * NBT));

	float3 matBaseColor;
	CalculateMatBaseColor(uniforms, In.TexCoords0, matBaseColor, _DefaultWrapSampler, Texture2DParameter_basecolor_DefaultWrapSampler, Texture2DParameter_MSKskin_DefaultWrapSampler, Texture2DParameter_MSKcloth_DefaultWrapSampler);
	float matMetalMask;
	CalculateMatMetalMask(In.TexCoords0, matMetalMask, _DefaultWrapSampler, Texture2DParameter_physicalmap_DefaultWrapSampler);
	float matReflectance;
	CalculateMatReflectance(uniforms, matReflectance);
	matReflectance = RemapReflectance(matReflectance);
	float matRoughness;
	CalculateMatRoughness(In.TexCoords0, matRoughness, _DefaultWrapSampler, Texture2DParameter_physicalmap_DefaultWrapSampler);
	matRoughness = max(0.09f, matRoughness);
	float matAnisotropy;
	CalculateMatAnisotropy(matAnisotropy);
	matAnisotropy = saturate(matAnisotropy);
	float3 FinalColor = float3(0.0f, 0.0f, 0.0f);

	//Calculate Image Based Lighting
	//Normalized world space view vector
	float3 worldViewNormalized = normalize(In.WorldView);

	float3 iblDiffuse;
	float3 iblSpecular;
	EvaluateDistantIBL(matBaseColor, matRoughness, float3(matReflectance, matReflectance, matReflectance), matMetalMask, matNormal, worldViewNormalized, iblDiffuse, iblSpecular, IBL_PARAMS_CONSTRUCT);
	FinalColor = ((FinalColor + iblDiffuse) + iblSpecular);

	float3 LightDiffuseColorOut;
	float3 LightSpecularColorOut;
	DirectionLight_Aniso(matNormal, PatchTangent(matNormal, worldTangentNormalized), worldViewNormalized, perFrame.global_LightPropertyMatrix, matBaseColor, matReflectance, matRoughness, matMetalMask, matAnisotropy, LightDiffuseColorOut, LightSpecularColorOut);
	FinalColor = ((FinalColor + LightDiffuseColorOut) + LightSpecularColorOut);

	FinalColor = PreExpose(FinalColor, Exposure);

	FinalColor = mix(perFrame.global_FogPropertyMatrix[1].xyz, FinalColor, float3(In.HeightFog, In.HeightFog, In.HeightFog));
	FinalColor = mix(perFrame.global_FogPropertyMatrix[0].xyz, FinalColor, float3(In.DistanceFog, In.DistanceFog, In.DistanceFog));

	Out.Color0 = float4(FinalColor, matOpacity);
	Out.Color0 = max(Out.Color0, 0.0f);

	return Out;
}
