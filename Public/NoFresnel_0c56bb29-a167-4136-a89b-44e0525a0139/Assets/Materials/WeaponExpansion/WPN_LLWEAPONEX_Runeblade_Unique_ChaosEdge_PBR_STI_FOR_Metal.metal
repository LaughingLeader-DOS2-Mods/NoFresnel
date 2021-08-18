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
	float4 InstanceMatrix1 COLOR1;
	float4 InstanceMatrix2 COLOR2;
	float4 InstanceMatrix3 COLOR3;
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


vertex VertexOutput WeaponExpansion_WPN_LLWEAPONEX_Runeblade_Unique_ChaosEdge_PBR_STI_FOR_Metal_vertexMain(constant PerView& perView [[buffer(5)]],
	constant PerFrame& perFrame [[buffer(6)]],
	VertexInput In [[stage_in]])
{
	VertexOutput Out;

	//Create Instance World Matrix
	float4 col1 = float4(In.InstanceMatrix1.x, In.InstanceMatrix1.y, In.InstanceMatrix1.z, 0.0f);
	float4 col2 = float4(In.InstanceMatrix1.w, In.InstanceMatrix2.x, In.InstanceMatrix2.y, 0.0f);
	float4 col3 = float4(In.InstanceMatrix2.z, In.InstanceMatrix2.w, In.InstanceMatrix3.x, 0.0f);
	float4 col4 = float4(In.InstanceMatrix3.y, In.InstanceMatrix3.z, In.InstanceMatrix3.w, 1.0f);
	float4x4 WorldMatrix = float4x4(col1, col2, col3, col4);

	//World space position
	float4 worldPosition = (WorldMatrix * float4(In.Position, 1.0f));

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
	float3 worldNormal = (float3x3(WorldMatrix[0].xyz, WorldMatrix[1].xyz, WorldMatrix[2].xyz) * localNormalNormalized);

	//Normalize World Normal
	float3 worldNormalNormalized = normalize(worldNormal);

	Out.WorldNormal = worldNormalNormalized;

	float3 LocalBinormal = LocalTangentFrame[1];

	//Normalize Local Binormal
	float3 localBinormalNormalized = normalize(LocalBinormal);

	//World space Binormal
	float3 worldBinormal = (float3x3(WorldMatrix[0].xyz, WorldMatrix[1].xyz, WorldMatrix[2].xyz) * localBinormalNormalized);

	//Normalize World Binormal
	float3 worldBinormalNormalized = normalize(worldBinormal);

	Out.WorldBinormal = worldBinormalNormalized;

	float3 LocalTangent = LocalTangentFrame[0];

	//Normalize Local Tangent
	float3 localTangentNormalized = normalize(LocalTangent);

	//World space Tangent
	float3 worldTangent = (float3x3(WorldMatrix[0].xyz, WorldMatrix[1].xyz, WorldMatrix[2].xyz) * localTangentNormalized);

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
	float4 Vector4Parameter_Color3;
	float4 Vector4Parameter_Color4;
	float4 Vector4Parameter_Color5;
	EXPOSURE_UNIFORMS
	IBL_UNIFORMS
};

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
	texture2d<float> Texture2DParameter_MSKcloth_DefaultWrapSampler,
	texture2d<float> Texture2DParameter_basecolor_DefaultWrapSampler)
{
	float4 Local0 = Texture2DParameter_MSKcloth_DefaultWrapSampler.sample(_DefaultWrapSampler, in_0);
	//[Local0] Get needed components
	float Local1 = Local0.x;
	float Local2 = Local0.y;
	float Local3 = Local0.z;
	float4 Local4 = (uniforms.Vector4Parameter_Color3 * Local1);
	float4 Local5 = (uniforms.Vector4Parameter_Color4 * Local2);
	float4 Local6 = (Local4 + Local5);
	float4 Local7 = (uniforms.Vector4Parameter_Color5 * Local3);
	float4 Local8 = (Local6 + Local7);
	float Local9 = (1.0f - Local1);
	float Local10 = (1.0f - Local2);
	float Local11 = (Local9 * Local10);
	float Local12 = (1.0f - Local3);
	float Local13 = (Local11 * Local12);
	float Local14 = pow(Local13, 2.2f);
	float4 Local15 = (Local8 + Local14);
	float3 Local16 = Local15.xyz;
	float4 Local17 = Texture2DParameter_basecolor_DefaultWrapSampler.sample(_DefaultWrapSampler, in_0);
	//[Local17] Get needed components
	float3 Local18 = Local17.xyz;
	float3 Local19 = (Local16 * Local18);
	out_0 = Local19;
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

static void CalculateMatReflectance(thread float& out_0)
{
	out_0 = 0.5f;
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

fragment PixelOutput WeaponExpansion_WPN_LLWEAPONEX_Runeblade_Unique_ChaosEdge_PBR_STI_FOR_Metal_fragmentMain(constant LocalUniformsPS& uniforms,
	constant PerFrame& perFrame,
	VertexOutput In [[stage_in]],
	sampler _DefaultWrapSampler,
	texture2d<float> Texture2DParameter_normalmap_DefaultWrapSampler,
	texture2d<float> Texture2DParameter_MSKcloth_DefaultWrapSampler,
	texture2d<float> Texture2DParameter_basecolor_DefaultWrapSampler,
	texture2d<float> Texture2DParameter_physicalmap_DefaultWrapSampler,
	EXPOSURE_PARAMS,
	IBL_PARAMS)
{
	PixelOutput Out;

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
	CalculateMatBaseColor(uniforms, In.TexCoords0, matBaseColor, _DefaultWrapSampler, Texture2DParameter_MSKcloth_DefaultWrapSampler, Texture2DParameter_basecolor_DefaultWrapSampler);
	float matMetalMask;
	CalculateMatMetalMask(In.TexCoords0, matMetalMask, _DefaultWrapSampler, Texture2DParameter_physicalmap_DefaultWrapSampler);
	float matReflectance;
	CalculateMatReflectance(matReflectance);
	matReflectance = RemapReflectance(matReflectance);
	float matRoughness;
	CalculateMatRoughness(In.TexCoords0, matRoughness, _DefaultWrapSampler, Texture2DParameter_physicalmap_DefaultWrapSampler);
	matRoughness = max(0.09f, matRoughness);
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
	DirectionLight(matNormal, worldViewNormalized, perFrame.global_LightPropertyMatrix, matBaseColor, matReflectance, matRoughness, matMetalMask, LightDiffuseColorOut, LightSpecularColorOut);
	FinalColor = ((FinalColor + LightDiffuseColorOut) + LightSpecularColorOut);

	FinalColor = PreExpose(FinalColor, Exposure);

	FinalColor = mix(perFrame.global_FogPropertyMatrix[1].xyz, FinalColor, float3(In.HeightFog, In.HeightFog, In.HeightFog));
	FinalColor = mix(perFrame.global_FogPropertyMatrix[0].xyz, FinalColor, float3(In.DistanceFog, In.DistanceFog, In.DistanceFog));

	Out.Color0 = float4(FinalColor, uniforms._OpacityFade);
	Out.Color0 = max(Out.Color0, 0.0f);

	return Out;
}
