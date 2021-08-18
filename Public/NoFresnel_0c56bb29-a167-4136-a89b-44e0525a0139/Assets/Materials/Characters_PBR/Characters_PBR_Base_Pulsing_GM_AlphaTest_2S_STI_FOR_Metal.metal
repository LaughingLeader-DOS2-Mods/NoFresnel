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


vertex VertexOutput Characters_PBR_Characters_PBR_Base_Pulsing_GM_AlphaTest_2S_STI_FOR_Metal_vertexMain(constant PerView& perView [[buffer(5)]],
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
	float3 Vector3Parameter_GlowColor;
	float2 Vector2Parameter_XYPanningSpeeds;
	float FloatParameter_GlowMultiplier;
	float FloatParameter_AddedColorRepeat;
	float FloatParameter_AddWordPositionColor;
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

static void CalculateMatEmissiveColor(constant LocalUniformsPS& uniforms,
	constant PerFrame& perFrame,
	float2 in_0,
	float3 in_1,
	thread float3& out_0,
	sampler _DefaultWrapSampler,
	texture2d<float> Texture2DParameter_Glowmap_DefaultWrapSampler,
	texture2d<float> Texture2DParameter_PanningNoise_DefaultWrapSampler,
	texture2d<float> Texture2DParameter_9dc5807b36974b8fab0fb9c5c1bd7010_DefaultWrapSampler,
	texture2d<float> Texture2DParameter_WorldPositionColorMap_DefaultWrapSampler,
	texture2d<float> Texture2DParameter_normalmap_DefaultWrapSampler)
{
	float4 Local0 = Texture2DParameter_Glowmap_DefaultWrapSampler.sample(_DefaultWrapSampler, in_0);
	//[Local0] Get needed components
	float Local1 = Local0.x;
	float3 Local2 = (uniforms.Vector3Parameter_GlowColor * Local1);
	float2 Local3 = fma(perFrame.global_Data.x, uniforms.Vector2Parameter_XYPanningSpeeds, in_0);
	float4 Local4 = Texture2DParameter_PanningNoise_DefaultWrapSampler.sample(_DefaultWrapSampler, Local3);
	//[Local4] Get needed components
	float Local5 = Local4.x;
	float Local6 = (Local5 * uniforms.FloatParameter_GlowMultiplier);
	float3 Local7 = (Local2 * Local6);
	float2 Local8 = (in_0 * uniforms.FloatParameter_AddedColorRepeat);
	float4 Local9 = Texture2DParameter_9dc5807b36974b8fab0fb9c5c1bd7010_DefaultWrapSampler.sample(_DefaultWrapSampler, (Local8 + (float2(0.05f, 0.03f) * perFrame.global_Data.x)));
	//[Local9] Get needed components
	float Local10 = Local9.x;
	float4 Local11 = Texture2DParameter_WorldPositionColorMap_DefaultWrapSampler.sample(_DefaultWrapSampler, float2(Local10, Local10));
	//[Local11] Get needed components
	float3 Local12 = Local11.xyz;
	float3 Local13 = (Local12 * uniforms.FloatParameter_AddWordPositionColor);
	float4 Local14 = Texture2DParameter_normalmap_DefaultWrapSampler.sample(_DefaultWrapSampler, in_0);
	//[Local14] Convert normalmaps to tangent space vectors
	Local14.xyzw = Local14.wzyx;
	Local14.xyz = ((Local14.xyz * 2.0f) - 1.0f);
	Local14.z = -(Local14.z);
	Local14.xyz = normalize(Local14.xyz);
	//[Local14] Get needed components
	float3 Local15 = Local14.xyz;
	float Local16 = pow((1.0f - saturate(dot(Local15, in_1))), 2.0f);
	float3 Local17 = (Local13 * Local16);
	float3 Local18 = (Local17 * 3.0f);
	float3 Local19 = (Local18 / 2.0f);
	float3 Local20 = (Local7 + Local19);
	out_0 = Local20;
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
	constant PerFrame& perFrame,
	float2 in_0,
	float3 in_1,
	thread float3& out_0,
	sampler _DefaultWrapSampler,
	texture2d<float> Texture2DParameter_basecolor_DefaultWrapSampler,
	texture2d<float> Texture2DParameter_9dc5807b36974b8fab0fb9c5c1bd7010_DefaultWrapSampler,
	texture2d<float> Texture2DParameter_WorldPositionColorMap_DefaultWrapSampler,
	texture2d<float> Texture2DParameter_normalmap_DefaultWrapSampler)
{
	float2 Local0 = (in_0 * uniforms.FloatParameter_AddedColorRepeat);
	float4 Local1 = Texture2DParameter_9dc5807b36974b8fab0fb9c5c1bd7010_DefaultWrapSampler.sample(_DefaultWrapSampler, (Local0 + (float2(0.05f, 0.03f) * perFrame.global_Data.x)));
	//[Local1] Get needed components
	float Local2 = Local1.x;
	float4 Local3 = Texture2DParameter_WorldPositionColorMap_DefaultWrapSampler.sample(_DefaultWrapSampler, float2(Local2, Local2));
	//[Local3] Get needed components
	float3 Local4 = Local3.xyz;
	float3 Local5 = (Local4 * uniforms.FloatParameter_AddWordPositionColor);
	float4 Local6 = Texture2DParameter_normalmap_DefaultWrapSampler.sample(_DefaultWrapSampler, in_0);
	//[Local6] Convert normalmaps to tangent space vectors
	Local6.xyzw = Local6.wzyx;
	Local6.xyz = ((Local6.xyz * 2.0f) - 1.0f);
	Local6.z = -(Local6.z);
	Local6.xyz = normalize(Local6.xyz);
	//[Local6] Get needed components
	float3 Local7 = Local6.xyz;
	float Local8 = pow((1.0f - saturate(dot(Local7, in_1))), 2.0f);
	float3 Local9 = (Local5 * Local8);
	float3 Local10 = (Local9 * 3.0f);
	float4 Local11 = Texture2DParameter_basecolor_DefaultWrapSampler.sample(_DefaultWrapSampler, in_0);
	//[Local11] Get needed components
	float3 Local12 = Local11.xyz;
	float Local13 = Local11.w;
	float3 Local14 = (Local10 + Local12);
	out_0 = Local14;
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

fragment PixelOutput Characters_PBR_Characters_PBR_Base_Pulsing_GM_AlphaTest_2S_STI_FOR_Metal_fragmentMain(constant LocalUniformsPS& uniforms,
	constant PerFrame& perFrame,
	VertexOutput In [[stage_in]],
	bool IsFrontFacing [[front_facing]],
	sampler _DefaultWrapSampler,
	texture2d<float> Texture2DParameter_basecolor_DefaultWrapSampler,
	texture2d<float> Texture2DParameter_Glowmap_DefaultWrapSampler,
	texture2d<float> Texture2DParameter_PanningNoise_DefaultWrapSampler,
	texture2d<float> Texture2DParameter_9dc5807b36974b8fab0fb9c5c1bd7010_DefaultWrapSampler,
	texture2d<float> Texture2DParameter_WorldPositionColorMap_DefaultWrapSampler,
	texture2d<float> Texture2DParameter_normalmap_DefaultWrapSampler,
	texture2d<float> Texture2DParameter_physicalmap_DefaultWrapSampler,
	EXPOSURE_PARAMS,
	IBL_PARAMS)
{
	PixelOutput Out;

	float matOpacity;
	CalculateMatOpacity(In.TexCoords0, matOpacity, _DefaultWrapSampler, Texture2DParameter_basecolor_DefaultWrapSampler);
	matOpacity = (matOpacity * uniforms._OpacityFade);

	if ((matOpacity - (0.5f * uniforms._OpacityFade)) < 0) discard_fragment();

	float3 matEmissiveColor;
	//Flip back-facing WorldSpace Normal
	float FrontFace = (((float)(IsFrontFacing) * 2.0f) - 1.0f);
	float3 WorldNormal = (In.WorldNormal * FrontFace);

	//Normalize World Normal
	float3 worldNormalNormalized = normalize(WorldNormal);

	//Normalize World Binormal
	float3 worldBinormalNormalized = normalize(In.WorldBinormal);

	//Normalize World Tangent
	float3 worldTangentNormalized = normalize(In.WorldTangent);

	float3x3 NBT = float3x3(float3(worldTangentNormalized.x, worldNormalNormalized.x, worldBinormalNormalized.x), float3(worldTangentNormalized.y, worldNormalNormalized.y, worldBinormalNormalized.y), float3(worldTangentNormalized.z, worldNormalNormalized.z, worldBinormalNormalized.z));

	//Normalized world space view vector
	float3 worldViewNormalized = normalize(In.WorldView);

	//Calculate tangent space view vector
	float3 tangentView = (NBT * worldViewNormalized);

	CalculateMatEmissiveColor(uniforms, perFrame, In.TexCoords0, tangentView, matEmissiveColor, _DefaultWrapSampler, Texture2DParameter_Glowmap_DefaultWrapSampler, Texture2DParameter_PanningNoise_DefaultWrapSampler, Texture2DParameter_9dc5807b36974b8fab0fb9c5c1bd7010_DefaultWrapSampler, Texture2DParameter_WorldPositionColorMap_DefaultWrapSampler, Texture2DParameter_normalmap_DefaultWrapSampler);
	float3 matNormal;
	CalculateMatNormal(In.TexCoords0, matNormal, _DefaultWrapSampler, Texture2DParameter_normalmap_DefaultWrapSampler);
	matNormal = normalize((matNormal * NBT));

	float3 matBaseColor;
	CalculateMatBaseColor(uniforms, perFrame, In.TexCoords0, tangentView, matBaseColor, _DefaultWrapSampler, Texture2DParameter_basecolor_DefaultWrapSampler, Texture2DParameter_9dc5807b36974b8fab0fb9c5c1bd7010_DefaultWrapSampler, Texture2DParameter_WorldPositionColorMap_DefaultWrapSampler, Texture2DParameter_normalmap_DefaultWrapSampler);
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

	Out.Color0 = float4(FinalColor, matOpacity);
	Out.Color0 = max(Out.Color0, 0.0f);

	return Out;
}
