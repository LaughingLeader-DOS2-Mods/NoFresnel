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
	float Depth;
	float HeightFog;
	float DistanceFog;
} VertexOutput;


vertex VertexOutput WeaponExpansion_LLWEAPONEX_Base_Characters_PBR_GM_Swirl_01_STI_FOR_Metal_vertexMain(constant PerView& perView [[buffer(5)]],
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

	//View space position
	float4 viewPosition = (perView.global_View * worldPosition);

	//Depth
	float depth = viewPosition.z;

	//Pass depth to pixel shader
	Out.Depth = depth;

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
	float FloatParameter_FresnelGlow;
	float FloatParameter_FresnelPower;
	float3 Vector3Parameter_FresnelColor;
	float FloatParameter_PulseSpeed;
	float FloatParameter_MinGlow;
	float FloatParameter_MaxGlow;
	float FloatParameter_GlowMultiplier;
	float3 Vector3Parameter_MainColor;
	float FloatParameter_Brightness;
	float FloatParameter_MultUVMagicWall;
	float FloatParameter_PanningSpeed;
	float2 Vector2Parameter_ValuePannerFirstCloud;
	float FloatParameter_PanningScaleBiasSpeed;
	float FloatParameter_CloudUVTilingMult;
	float FloatParameter_UseScaleBiasInsteadPanner;
	float2 Vector2Parameter_ValuePannerSecondCloud;
	float FloatParameter_TurnOffParallaxTexMagicWall;
	float FloatParameter_ObjectSize;
	float FloatParameter_TurnOffParallaxTexNM;
	float FloatParameter_FresnelMult;
	float FloatParameter_DepthDifferenceBlendDistance;
	float4 _MeshVertexColor;
	float FloatParameter_IntersectionBrightness;
	float3 Vector3Parameter_IntersectionColor;
	float FloatParameter_OpacityMultiplier;
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
	constant PerView& perView,
	constant PerFrame& perFrame,
	float2 in_0,
	float3 in_1,
	float2 in_2,
	float in_3,
	thread float3& out_0,
	sampler _DefaultWrapSampler,
	texture2d<float> Texture2DParameter_normalmap_DefaultWrapSampler,
	texture2d<float> Texture2DParameter_Glowmap_DefaultWrapSampler,
	texture2d<float> Texture2DParameter_b1f13545defa4e279372be633d7527fa_DefaultWrapSampler,
	texture2d<float> Texture2DParameter_869f49e445c44f38b201f8be549b2cfd_DefaultWrapSampler,
	texture2d<float> Texture2DParameter_TilingTextureBC4_DefaultWrapSampler,
	texture2d<float> Texture2DParameter_TilingTextureNM_DefaultWrapSampler,
	sampler _PointMirrorSampler,
	texture2d<float> _sceneDepth,
	texture2d<float> Texture2DParameter_PanningTextureBW_DefaultWrapSampler)
{
	float4 Local0 = Texture2DParameter_normalmap_DefaultWrapSampler.sample(_DefaultWrapSampler, in_0);
	//[Local0] Convert normalmaps to tangent space vectors
	Local0.xyzw = Local0.wzyx;
	Local0.xyz = ((Local0.xyz * 2.0f) - 1.0f);
	Local0.z = -(Local0.z);
	Local0.xyz = normalize(Local0.xyz);
	//[Local0] Get needed components
	float3 Local1 = Local0.xyz;
	float Local2 = pow((1.0f - saturate(dot(Local1, in_1))), uniforms.FloatParameter_FresnelPower);
	float Local3 = (uniforms.FloatParameter_FresnelGlow * Local2);
	float3 Local4 = (Local3 * uniforms.Vector3Parameter_FresnelColor);
	float Local5 = (perFrame.global_Data.x * uniforms.FloatParameter_PulseSpeed);
	float Local6 = ((((sin(Local5) * 0.5f) + 0.5f) * (uniforms.FloatParameter_MaxGlow - uniforms.FloatParameter_MinGlow)) + uniforms.FloatParameter_MinGlow);
	float4 Local7 = Texture2DParameter_Glowmap_DefaultWrapSampler.sample(_DefaultWrapSampler, in_0);
	//[Local7] Get needed components
	float3 Local8 = Local7.xyz;
	float2 Local9 = (in_0 * uniforms.FloatParameter_MultUVMagicWall);
	float Local10 = (perFrame.global_Data.x * uniforms.FloatParameter_PanningSpeed);
	float Local11 = (perFrame.global_Data.x * uniforms.FloatParameter_PanningScaleBiasSpeed);
	float2 Local12 = (in_0 * uniforms.FloatParameter_CloudUVTilingMult);
	float2 Local13 = fma(uniforms.Vector2Parameter_ValuePannerFirstCloud, Local11, Local12);
	float2 Local14 = mix((in_0 + (float2(0.19f, 0.1f) * Local10)), Local13, float2(uniforms.FloatParameter_UseScaleBiasInsteadPanner, uniforms.FloatParameter_UseScaleBiasInsteadPanner));
	float4 Local15 = Texture2DParameter_b1f13545defa4e279372be633d7527fa_DefaultWrapSampler.sample(_DefaultWrapSampler, Local14);
	//[Local15] Get needed components
	float Local16 = Local15.x;
	float2 Local17 = fma(uniforms.Vector2Parameter_ValuePannerSecondCloud, Local11, Local12);
	float2 Local18 = mix((in_0 + (float2(-0.16f, 0.17f) * Local10)), Local17, float2(uniforms.FloatParameter_UseScaleBiasInsteadPanner, uniforms.FloatParameter_UseScaleBiasInsteadPanner));
	float4 Local19 = Texture2DParameter_b1f13545defa4e279372be633d7527fa_DefaultWrapSampler.sample(_DefaultWrapSampler, Local18);
	//[Local19] Get needed components
	float Local20 = Local19.x;
	float Local21 = (Local16 * Local20);
	float Local22 = (Local21 - 0.5f);
	float Local23 = (Local22 * 0.05f);
	float2 Local24 = (Local9 + Local23);
	float2 Local25 = (in_0 + Local23);
	float2 Local26 = (Local25 + (((0.0f * 0.5f) - 0.25f) * float2(in_1.x, -(in_1.z))));
	float2 Local27 = mix(Local24, Local26, float2(uniforms.FloatParameter_TurnOffParallaxTexMagicWall, uniforms.FloatParameter_TurnOffParallaxTexMagicWall));
	float4 Local28 = Texture2DParameter_869f49e445c44f38b201f8be549b2cfd_DefaultWrapSampler.sample(_DefaultWrapSampler, Local27);
	//[Local28] Get needed components
	float Local29 = Local28.x;
	float Local30 = pow(Local21, 4.0f);
	float Local31 = (Local22 * 0.05f);
	float Local32 = (uniforms.FloatParameter_ObjectSize / 4.0f);
	float2 Local33 = (in_0 * Local32);
	float2 Local34 = (Local31 + Local33);
	float4 Local35 = Texture2DParameter_TilingTextureBC4_DefaultWrapSampler.sample(_DefaultWrapSampler, Local34);
	//[Local35] Get needed components
	float Local36 = Local35.x;
	float2 Local37 = (Local34 + (((Local36 * 0.02f) - 0.01f) * float2(in_1.x, -(in_1.z))));
	float2 Local38 = mix(Local34, Local37, float2(uniforms.FloatParameter_TurnOffParallaxTexNM, uniforms.FloatParameter_TurnOffParallaxTexNM));
	float4 Local39 = Texture2DParameter_TilingTextureNM_DefaultWrapSampler.sample(_DefaultWrapSampler, Local38);
	//[Local39] Convert normalmaps to tangent space vectors
	Local39.xyzw = Local39.wzyx;
	Local39.xyz = ((Local39.xyz * 2.0f) - 1.0f);
	Local39.z = -(Local39.z);
	Local39.xyz = normalize(Local39.xyz);
	//[Local39] Get needed components
	float3 Local40 = Local39.xyz;
	float Local41 = pow((1.0f - saturate(dot(Local40, in_1))), 5.0f);
	float Local42 = (Local41 * uniforms.FloatParameter_FresnelMult);
	float Local43 = (Local30 + Local42);
	float Local44 = (Local29 + Local43);
	float Local45 = (uniforms.FloatParameter_Brightness * Local44);
	float3 Local46 = (uniforms.Vector3Parameter_MainColor * Local45);
	//DepthDifferenceBlend
	float Local47 = (_sceneDepth.sample(_PointMirrorSampler, in_2).x * perView.global_ViewInfo.x);
	float Local48 = (Local47 - in_3);
	float Local49 = Local48;
	float Local50 = saturate((Local49 / max(uniforms.FloatParameter_DepthDifferenceBlendDistance, 0.0001f)));
	//~DepthDifferenceBlend

	float Local51 = (1.0f - Local50);
	float4 Local52 = Texture2DParameter_PanningTextureBW_DefaultWrapSampler.sample(_DefaultWrapSampler, Local34);
	//[Local52] Get needed components
	float Local53 = Local52.x;
	float4 Local54 = Texture2DParameter_PanningTextureBW_DefaultWrapSampler.sample(_DefaultWrapSampler, (in_0 * float2(0.4f, 0.4f)));
	//[Local54] Get needed components
	float Local55 = Local54.x;
	float Local56 = (Local53 * Local55);
	float Local57 = (1.0f - uniforms._MeshVertexColor.w);
	float Local58 = (Local57 - 0.1f);
	float Local59 = smoothstep(Local58, Local57, Local56);
	float Local60 = pow(Local59, 5.0f);
	float Local61 = (1.0f - Local60);
	float Local62 = (Local61 * 5.0f);
	float Local63 = (Local51 + Local62);
	float Local64 = (Local63 * uniforms.FloatParameter_IntersectionBrightness);
	float3 Local65 = (Local64 * uniforms.Vector3Parameter_IntersectionColor);
	float3 Local66 = (Local46 + Local65);
	float Local67 = pow(Local36, 5.0f);
	float Local68 = (Local67 * 0.5f);
	float Local69 = (Local21 + Local68);
	float Local70 = (Local69 * Local21);
	float Local71 = (Local70 * uniforms.FloatParameter_OpacityMultiplier);
	float Local72 = (Local71 + Local51);
	float Local73 = clamp(Local72, 0.0f, 0.5f);
	float Local74 = (Local73 * Local59);
	float3 Local75 = (Local66 * Local74);
	float3 Local76 = (Local8 * Local75);
	float3 Local77 = (uniforms.FloatParameter_GlowMultiplier * Local76);
	float3 Local78 = (Local6 * Local77);
	float3 Local79 = (Local4 + Local78);
	out_0 = Local79;
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

fragment PixelOutput WeaponExpansion_LLWEAPONEX_Base_Characters_PBR_GM_Swirl_01_STI_FOR_Metal_fragmentMain(constant LocalUniformsPS& uniforms,
	constant PerView& perView,
	constant PerFrame& perFrame,
	VertexOutput In [[stage_in]],
	sampler _DefaultWrapSampler,
	texture2d<float> Texture2DParameter_normalmap_DefaultWrapSampler,
	texture2d<float> Texture2DParameter_Glowmap_DefaultWrapSampler,
	texture2d<float> Texture2DParameter_b1f13545defa4e279372be633d7527fa_DefaultWrapSampler,
	texture2d<float> Texture2DParameter_869f49e445c44f38b201f8be549b2cfd_DefaultWrapSampler,
	texture2d<float> Texture2DParameter_TilingTextureBC4_DefaultWrapSampler,
	texture2d<float> Texture2DParameter_TilingTextureNM_DefaultWrapSampler,
	sampler _PointMirrorSampler,
	texture2d<float> _sceneDepth,
	texture2d<float> Texture2DParameter_PanningTextureBW_DefaultWrapSampler,
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

	//UV position
	float2 Local0 = (In.ProjectedPosition.xy / perView.global_ViewInfo.zw);

	CalculateMatEmissiveColor(uniforms, perView, perFrame, In.TexCoords0, tangentView, Local0, In.Depth, matEmissiveColor, _DefaultWrapSampler, Texture2DParameter_normalmap_DefaultWrapSampler, Texture2DParameter_Glowmap_DefaultWrapSampler, Texture2DParameter_b1f13545defa4e279372be633d7527fa_DefaultWrapSampler, Texture2DParameter_869f49e445c44f38b201f8be549b2cfd_DefaultWrapSampler, Texture2DParameter_TilingTextureBC4_DefaultWrapSampler, Texture2DParameter_TilingTextureNM_DefaultWrapSampler, _PointMirrorSampler, _sceneDepth, Texture2DParameter_PanningTextureBW_DefaultWrapSampler);
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
